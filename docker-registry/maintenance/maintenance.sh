#!/usr/bin/env bash
# Scheduler and job runner of the maintenance overlay (docker-compose.maintenance.yml).
#
#   weekly job   audit, tag retention (if enabled), dangling tags, empty repositories, dangling layer
#                links, then a final audit
#   monthly job  the weekly job plus garbage collection, which makes the registry read-only for a
#                couple of hours (pulls keep working, pushes get a 405)
#
# If the audit finds a live image with missing blobs (or cannot finish), the job stops before deleting
# anything. Every job writes a log under $MAINTENANCE_DATA_DIR/logs/.
#
# Nothing is deleted unless MAINTENANCE_DRY_RUN=false: until then every step only logs what it would do.
#
# TODO: alerting. For now a failed job is only visible in its log and in logs/history.log.
set -Eeuo pipefail

# The scripts live in maintenance/ but work on the service folder (.env, data/, the compose files),
# so run from there. `cd ..` keeps the path the folder was reached by (it can be a symlink),
# which matters because compose labels its containers with that path.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir/.."
# shellcheck source=registry-lib.sh
source "$script_dir/registry-lib.sh"

usage() {
  printf 'Usage: %s [daemon]                     run the scheduler (default)\n' "$0"
  printf '       %s run weekly|monthly [--dry-run|--delete]   run one job now\n' "$0"
  printf '       %s tick                       evaluate the schedule once (used by the daemon)\n' "$0"
  printf '       %s status                     show the settings and the latest runs\n' "$0"
  printf '\n'
  printf 'Settings come from the environment (see .env.sample, MAINTENANCE_*).\n'
}

DATA="${MAINTENANCE_DATA_DIR:-/maintenance}"
WEEKLY_AT="${MAINTENANCE_WEEKLY_AT:-Mon 06:00}"
GC_AT="${MAINTENANCE_GC_AT:-first-Sun 03:00}"
DRY_RUN="${MAINTENANCE_DRY_RUN:-true}"
MIN_AGE_HOURS="${MAINTENANCE_MIN_AGE_HOURS:-24}"
KEEP_TAGS="${MAINTENANCE_KEEP_TAGS:-0}"
PROTECTED_TAGS="${MAINTENANCE_PROTECTED_TAGS:-latest,main,v*}"
LOG_DAYS="${MAINTENANCE_LOG_RETENTION_DAYS:-90}"
# a job missed by more than this (container was down) is skipped rather than run late
CATCH_UP_MINUTES=60

# "off" (or empty) disables the monthly garbage collection
if [[ "$GC_AT" == off ]]; then GC_AT=''; fi
if [[ -n "${MAINTENANCE_TZ:-}" ]]; then export TZ="$MAINTENANCE_TZ"; fi

# the scripts share a work dir with the aws-cli containers they start, and keep GC logs with ours
export MAINTENANCE_DATA_DIR="$DATA"
export MAINTENANCE_WORKDIR="$DATA/work"
export GC_LOG_DIR="$DATA/logs"

# MAINTENANCE_FAKE_NOW lets the tests pretend it is another time
now() { date ${MAINTENANCE_FAKE_NOW:+-d "$MAINTENANCE_FAKE_NOW"} "$@"; }
log() { printf '%s %s\n' "$(now +%FT%T%z)" "$*"; }

# A stop signal (docker stop, reboot) is forwarded to the step that is running, so that garbage
# collection can put the registry back in read-write mode before the container goes away. Steps after
# that are skipped.
STOPPING=''
CHILD=''
on_signal() {
  STOPPING=1
  if [[ -n "$CHILD" ]]; then kill -TERM "$CHILD" 2>/dev/null || true; fi
}
trap on_signal TERM INT

day_re='(Mon|Tue|Wed|Thu|Fri|Sat|Sun)'
time_re='([01][0-9]|2[0-3]):[0-5][0-9]'

validate_settings() {
  local bad=0
  if ! [[ "$WEEKLY_AT" =~ ^${day_re}\ ${time_re}$ ]]; then
    log "MAINTENANCE_WEEKLY_AT='$WEEKLY_AT' is not valid; expected e.g. 'Mon 06:00'"; bad=1
  fi
  if [[ -n "$GC_AT" ]] && ! [[ "$GC_AT" =~ ^first-${day_re}\ ${time_re}$ ]]; then
    log "MAINTENANCE_GC_AT='$GC_AT' is not valid; expected e.g. 'first-Sun 03:00', or 'off' to disable"; bad=1
  fi
  [[ "$DRY_RUN" == true || "$DRY_RUN" == false ]] || { log "MAINTENANCE_DRY_RUN must be true or false, not '$DRY_RUN'"; bad=1; }
  [[ "$MIN_AGE_HOURS" =~ ^[0-9]+$ ]] || { log "MAINTENANCE_MIN_AGE_HOURS must be a number"; bad=1; }
  [[ "$KEEP_TAGS" =~ ^[0-9]+$ ]] || { log "MAINTENANCE_KEEP_TAGS must be a number (0 turns retention off)"; bad=1; }
  [[ "$LOG_DAYS" =~ ^[0-9]+$ ]] || { log "MAINTENANCE_LOG_RETENTION_DAYS must be a number"; bad=1; }
  return "$bad"
}

# ------------------------------------------------------------------------------------ jobs
# Runs one step, logging its command line and result; returns the step's exit status.
step() { # label command...
  local label="$1" rc=0
  shift
  if [[ -n "$STOPPING" ]]; then
    log "--- $label: skipped, shutting down"
    return 143
  fi
  log "--- $label: $*"
  "$@" &
  CHILD=$!
  wait "$CHILD" || rc=$?
  # a signal interrupts `wait`; keep waiting so the step can finish its cleanup
  while kill -0 "$CHILD" 2>/dev/null; do wait "$CHILD" || rc=$?; done
  CHILD=''
  log "--- $label finished with status $rc"
  return "$rc"
}

job_body() { # weekly|monthly
  local job="$1" rc del=()
  [[ "$DRY_RUN" == false ]] && del=(--delete --yes)
  log "job '$job' started (dry run: $DRY_RUN)"

  rc=0
  step 'audit' ./maintenance/registry-audit.sh --verify-refs || rc=$?
  case "$rc" in
    0) ;;
    10) log 'the audit found dangling tags; they are removed below' ;;
    20) log 'STOP: a live image references blobs that no longer exist. Nothing was deleted; fix this first.'; return 20 ;;
    *) log 'STOP: the audit could not complete. Nothing was deleted.'; return 1 ;;
  esac

  if [[ "$KEEP_TAGS" -gt 0 ]]; then
    step 'tag retention' ./maintenance/prune-old-tags.sh --keep "$KEEP_TAGS" --protect "$PROTECTED_TAGS" --all ${del[@]+"${del[@]}"} || return 1
  else
    log '--- tag retention: off (MAINTENANCE_KEEP_TAGS=0)'
  fi
  step 'dangling tags' ./maintenance/prune-empty-repos.sh --dangling-tags --all ${del[@]+"${del[@]}"} || return 1
  step 'empty repositories' ./maintenance/prune-empty-repos.sh --empty --min-age "$MIN_AGE_HOURS" ${del[@]+"${del[@]}"} || return 1
  step 'dangling layer links' ./maintenance/prune-empty-repos.sh --dangling-layers --all ${del[@]+"${del[@]}"} || return 1

  if [[ "$job" == monthly ]]; then
    if [[ "$DRY_RUN" == false ]]; then
      step 'garbage collection' ./maintenance/garbage-collect.sh --delete --delete-untagged --yes || return 1
    else
      step 'garbage collection (dry run)' ./maintenance/garbage-collect.sh --dry-run --delete-untagged || return 1
    fi
  fi

  if [[ "$DRY_RUN" == false ]]; then
    rc=0
    step 'final audit' ./maintenance/registry-audit.sh --verify-refs || rc=$?
    [[ "$rc" -eq 0 ]] || { log "the final audit reported status $rc"; return 1; }
  fi
  log "job '$job' finished"
}

rotate_logs() {
  find "$DATA/logs" -type f -name '*.log' -mtime "+$LOG_DAYS" -print -delete | sed 's/^/removed old log: /' || true
}

run_job() { # weekly|monthly
  local job="$1" log_file fifo rc=0 started tee_pid
  exec 9>"$DATA/state/lock"
  if ! flock -n 9; then
    log "another maintenance job is already running; '$job' skipped"
    return 1
  fi
  started="$(date +%s)"
  log_file="$DATA/logs/$(date +%Y%m%dT%H%M%S)-$job.log"
  # The job runs in this shell (a pipeline would put it in a subshell that never sees stop signals);
  # its output goes to the container log and to its own file through a FIFO.
  fifo="$DATA/state/job.fifo"
  rm -f "$fifo"
  mkfifo "$fifo"
  tee -a "$log_file" < "$fifo" &
  tee_pid=$!
  exec 3>&1 4>&2
  exec > "$fifo" 2>&1
  job_body "$job" || rc=$?
  exec 1>&3 2>&4 3>&- 4>&-
  wait "$tee_pid" || true
  rm -f "$fifo"
  printf '%s %s status=%s dry_run=%s seconds=%s log=%s\n' "$(now +%FT%T%z)" "$job" "$rc" "$DRY_RUN" "$(( $(date +%s) - started ))" "$log_file" \
    >> "$DATA/logs/history.log"
  rotate_logs
  flock -u 9
  return "$rc"
}

# ------------------------------------------------------------------------------------ schedule
# 0 if "<Day> HH:MM" is due now: the right weekday, and 0..CATCH_UP_MINUTES minutes past the time
due() { # day hh:mm [first]   ("first" restricts it to the first seven days of the month)
  local day="$1" hm="$2" first="${3:-}" minutes late
  [[ "$(now +%a)" == "$day" ]] || return 1
  if [[ "$first" == first && "$(now +%-d)" -gt 7 ]]; then return 1; fi
  minutes=$(( 10#$(now +%H) * 60 + 10#$(now +%M) ))
  late=$(( minutes - (10#${hm%%:*} * 60 + 10#${hm##*:}) ))
  [[ "$late" -ge 0 && "$late" -lt "$CATCH_UP_MINUTES" ]]
}

tick() {
  local weekly_slot monthly_slot
  weekly_slot="$(now +%G-W%V)"
  monthly_slot="$(now +%Y-%m)"

  if [[ -n "$GC_AT" ]]; then
    local gc_day="${GC_AT#first-}"; gc_day="${gc_day%% *}"
    if due "$gc_day" "${GC_AT##* }" first && [[ "$(cat "$DATA/state/last-monthly" 2>/dev/null || true)" != "$monthly_slot" ]]; then
      echo "$monthly_slot" > "$DATA/state/last-monthly"
      # the monthly job contains the weekly steps, so it also satisfies this week's slot
      echo "$weekly_slot" > "$DATA/state/last-weekly"
      run_job monthly || true
      return 0
    fi
  fi
  if due "${WEEKLY_AT%% *}" "${WEEKLY_AT##* }" && [[ "$(cat "$DATA/state/last-weekly" 2>/dev/null || true)" != "$weekly_slot" ]]; then
    echo "$weekly_slot" > "$DATA/state/last-weekly"
    run_job weekly || true
  fi
}

# A garbage collection that was cut short (container killed, host rebooted) leaves its generated
# files behind and the registry running read-only. Undo that, unless a collection is running right now.
heal_interrupted_gc() {
  local cid
  [[ -f docker-compose.gc-readonly.yml ]] || return 0
  cid="$(registry_container -a)"
  if [[ -n "$cid" ]] && docker top "$cid" 2>/dev/null | grep -q garbage-collect; then
    log 'a garbage collection is running; leaving the read-only registry alone'
    return 0
  fi
  log 'WARNING: an earlier garbage collection was interrupted and left the registry read-only; reverting'
  ./maintenance/garbage-collect.sh --revert || log 'could not revert; run ./maintenance/garbage-collect.sh --revert by hand'
}

daemon() {
  validate_settings || exit 1
  log "scheduler started: weekly '$WEEKLY_AT', garbage collection '${GC_AT:-off}', dry run: $DRY_RUN, timezone: $(date +%Z)"
  if [[ "$DRY_RUN" == true ]]; then
    log 'DRY RUN: jobs only log what they would delete. Set MAINTENANCE_DRY_RUN=false to enable deletions.'
  fi
  rotate_logs
  heal_interrupted_gc
  while [[ -z "$STOPPING" ]]; do
    tick
    # sleep in the background so that a stop signal ends it at once
    sleep 30 &
    CHILD=$!
    wait "$CHILD" || true
    CHILD=''
  done
  log 'scheduler stopped'
}

status() {
  log "weekly '$WEEKLY_AT', garbage collection '${GC_AT:-off}', dry run $DRY_RUN, grace period ${MIN_AGE_HOURS}h"
  if [[ "$KEEP_TAGS" -gt 0 ]]; then
    log "tag retention: keep the newest $KEEP_TAGS tags per repository (protected: $PROTECTED_TAGS)"
  else
    log 'tag retention: off'
  fi
  log 'latest runs:'
  tail -n 10 "$DATA/logs/history.log" 2>/dev/null || log '  (none yet)'
}

init_dirs() { mkdir -p "$DATA/logs" "$DATA/state" "$DATA/work"; }

case "${1:-daemon}" in
  daemon) init_dirs; daemon ;;
  tick) init_dirs; validate_settings || exit 1; tick ;;
  status) init_dirs; status ;;
  run)
    job="${2:-}"
    [[ "$job" == weekly || "$job" == monthly ]] || { usage >&2; exit 2; }
    case "${3:-}" in
      '') ;;
      --dry-run) DRY_RUN=true ;;
      --delete) DRY_RUN=false ;;
      *) usage >&2; exit 2 ;;
    esac
    init_dirs
    validate_settings || exit 1
    run_job "$job"
    ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
