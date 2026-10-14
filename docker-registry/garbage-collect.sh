#!/usr/bin/env bash
# Garbage-collect the registry (S3 storage).
#
# --delete runs with the registry in read-only mode: pulls keep working, pushes are rejected (405)
# for the duration, then the registry is put back. The mark phase is read-only, so when S3 resets a
# connection the run is simply retried.
#
# Read-only mode needs `storage.maintenance.readonly.enabled` in a config file. It cannot be set from
# env vars, and `REGISTRY_STORAGE=s3` in the environment silently discards it, so while GC runs the
# registry container gets a generated config file and a reduced environment (see the guard below).
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=registry-lib.sh
source ./registry-lib.sh

usage() {
  printf 'Usage: %s [--dry-run] [--delete] [--yes] [--delete-untagged] [--stop-registry] [--retries N]\n' "$0"
  printf '       %s --revert\n' "$0"
  printf '\n'
  printf '  --dry-run          Report unreferenced blobs without deleting them (default)\n'
  printf '  --delete           Delete unreferenced blobs from S3 (registry runs read-only meanwhile)\n'
  printf '  --yes              With --delete: skip the typed DELETE prompt (for runs without a terminal)\n'
  printf '  --delete-untagged  Also delete manifests not referenced by a tag\n'
  printf '  --stop-registry    With --delete: stop the registry completely instead of read-only mode\n'
  printf '  --retries N        Attempts when GC fails, e.g. on an S3 connection reset (default 6)\n'
  printf '  --revert           Undo an interrupted --delete: put the registry back in read-write mode\n'
  printf '\n'
  printf 'A full run takes hours on a large bucket: run it inside tmux/screen or with nohup.\n'
}

mode="--dry-run"
assume_yes=0
revert_only=0
delete_untagged=""
stop_registry=0
retries=6

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      mode="--dry-run"
      ;;
    --delete)
      mode=""
      ;;
    --yes)
      assume_yes=1
      ;;
    --revert)
      revert_only=1
      ;;
    --delete-untagged)
      delete_untagged="--delete-untagged"
      ;;
    --stop-registry)
      stop_registry=1
      ;;
    --retries)
      shift
      retries="${1:-}"
      [[ "$retries" =~ ^[1-9][0-9]*$ ]] || { printf '%s\n' '--retries needs a positive number.' >&2; exit 2; }
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ "$assume_yes" -eq 1 && "$mode" == "--dry-run" ]]; then
  printf '%s\n' '--yes only applies together with --delete.' >&2
  exit 2
fi
if [[ "$stop_registry" -eq 1 && "$mode" == "--dry-run" ]]; then
  printf '%s\n' '--stop-registry only applies together with --delete.' >&2
  exit 2
fi

# Use whichever compose files the running stack was started with (e.g. the traefik variant).
if [[ "$revert_only" -eq 1 ]]; then existing="$(registry_container -a)"; else existing="$(registry_container)"; fi
compose=(docker compose)
if [[ -n "$existing" ]]; then
  files="$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project.config_files"}}' "$existing")"
  IFS=',' read -r -a file_list <<< "$files"
  for f in "${file_list[@]}"; do
    # a registry left behind by an interrupted read-only run lists this override among its files
    if [[ "$f" == */docker-compose.gc-readonly.yml ]]; then continue; fi
    compose+=(-f "$f")
  done
fi

# An interrupted --delete (container killed, host rebooted) leaves the registry running read-only,
# because the generated config is part of the container that compose created.
if [[ "$revert_only" -eq 1 ]]; then
  [[ -n "$existing" ]] || { printf '%s\n' 'No registry container found.' >&2; exit 1; }
  rm -f docker-compose.gc-readonly.yml registry-readonly.gc.yml
  "${compose[@]}" up -d --no-deps registry
  "${compose[@]}" restart ui >/dev/null 2>&1 || true
  printf '%s\n' 'The registry was recreated from the normal compose files (read-write).'
  exit 0
fi

gc_args=(registry garbage-collect)
[[ -n "$mode" ]] && gc_args+=("$mode")
[[ -n "$delete_untagged" ]] && gc_args+=("$delete_untagged")
gc_args+=(/etc/distribution/config.yml)

mkdir -p "${GC_LOG_DIR:-.}"
log_file="${GC_LOG_DIR:-.}/gc-$(date -u +%Y%m%dT%H%M%SZ).log"

# GC through `docker exec` in the running registry, retrying on failure.
run_gc_with_retries() {
  local cid attempt rc
  cid="$("${compose[@]}" ps -q registry)"
  [[ -n "$cid" ]] || { printf '%s\n' 'Registry container is not running.' >&2; return 1; }
  for ((attempt = 1; attempt <= retries; attempt++)); do
    printf '=== GC attempt %d/%d at %s\n' "$attempt" "$retries" "$(date -u +%FT%TZ)" | tee -a "$log_file"
    rc=0
    # pipefail makes the pipeline fail with docker exec's status even though tee succeeds
    docker exec -e REGISTRY_LOG_LEVEL=info "$cid" "${gc_args[@]}" 2>&1 | tee -a "$log_file" || rc=$?
    if [[ "$rc" -eq 0 ]]; then
      return 0
    fi
    printf 'GC attempt %d failed (exit %s); the mark phase is read-only, so retrying is safe.\n' "$attempt" "$rc" | tee -a "$log_file"
    sleep 30
  done
  return 1
}

# ------------------------------------------------------------------------------------ dry run
if [[ "$mode" == "--dry-run" ]]; then
  printf '%s\n' 'Running garbage collection in DRY-RUN mode (registry stays up, nothing is deleted).'
  run_gc_with_retries
  printf 'Garbage collection dry run completed. Log: %s\n' "$log_file"
  exit 0
fi

# ------------------------------------------------------------------------------------ delete
printf '%s\n' 'WARNING: unreferenced blobs will be deleted from S3 (the bucket has no versioning).'
if [[ "$assume_yes" -eq 1 ]]; then
  printf '%s\n' '--yes given: continuing without the typed confirmation.'
else
  read -r -p 'Type DELETE to continue: ' confirmation || confirmation=''
  [[ "$confirmation" == "DELETE" ]] || {
    printf '%s\n' 'Cancelled.'
    exit 1
  }
fi

# ---- legacy behaviour: stop the registry for the whole run
if [[ "$stop_registry" -eq 1 ]]; then
  registry_was_running=0
  if "${compose[@]}" ps --status running --services | grep -qx registry; then
    registry_was_running=1
    "${compose[@]}" stop registry
  fi
  restart_registry() {
    if [[ "$registry_was_running" -eq 1 ]]; then
      "${compose[@]}" start registry
    fi
  }
  trap restart_registry EXIT
  "${compose[@]}" run --rm --no-deps registry "${gc_args[@]}"
  printf '%s\n' 'Garbage collection completed.'
  exit 0
fi

# ---- read-only mode
[[ -n "$existing" ]] || { printf '%s\n' 'The registry must be running (read-only mode recreates it).' >&2; exit 1; }
[[ -f .env ]] || { printf '%s\n' '.env not found.' >&2; exit 1; }
dotenv() { sed -n "s/^$1=//p" .env | head -n1; }
bucket="$(dotenv REGISTRY_STORAGE_S3_BUCKET)"
region="$(dotenv REGISTRY_STORAGE_S3_REGION)"
for v in REGISTRY_STORAGE_S3_ACCESSKEY REGISTRY_STORAGE_S3_SECRETKEY; do
  [[ -n "$(dotenv "$v")" ]] || { printf '%s is missing in .env (the read-only override reads it from there).\n' "$v" >&2; exit 1; }
done
[[ -n "$bucket" && -n "$region" ]] || { printf '%s\n' 'REGISTRY_STORAGE_S3_BUCKET / _REGION missing in .env.' >&2; exit 1; }

# Guard: the override replaces the registry's environment, so refuse if the compose file defines
# variables this script does not know it can drop or re-provide.
known='REGISTRY_AUTH REGISTRY_AUTH_HTPASSWD_REALM REGISTRY_AUTH_HTPASSWD_PATH
REGISTRY_STORAGE_S3_ACCESSKEY REGISTRY_STORAGE_S3_SECRETKEY
REGISTRY_HTTP_ADDR REGISTRY_STORAGE REGISTRY_STORAGE_S3_BUCKET REGISTRY_STORAGE_S3_REGION
REGISTRY_STORAGE_DELETE_ENABLED REGISTRY_HEALTH_STORAGEDRIVER_ENABLED
REGISTRY_REDIS_ADDR REGISTRY_REDIS_DB REGISTRY_REDIS_PASSWORD
REGISTRY_STORAGE_S3_REGIONENDPOINT REGISTRY_STORAGE_S3_FORCEPATHSTYLE REGISTRY_STORAGE_S3_SECURE
REGISTRY_STORAGE_REDIRECT_DISABLE'
current_keys="$("${compose[@]}" config 2>/dev/null \
  | awk '/^  registry:/{f=1; next} /^  [a-z]/{f=0} f && /^    environment:/{e=1; next} f && e && /^      [A-Za-z0-9_]+:/{sub(/:.*/, ""); gsub(/ /, ""); print; next} f && /^    [a-z]/{e=0}')"
unknown="$(comm -23 <(sort -u <<< "$current_keys") <(tr ' ' '\n' <<< "$known" | sed '/^$/d' | sort -u))"
if [[ -n "$unknown" ]]; then
  printf '%s\n' 'The registry environment has variables this script does not handle; refusing:' >&2
  printf '  %s\n' $unknown >&2
  printf '%s\n' 'Add them to the override below (or use --stop-registry).' >&2
  exit 1
fi

# Optional settings for S3-compatible storage (MinIO, Ceph, ...); AWS itself needs none of them.
s3_extra=''
for pair in regionendpoint:REGISTRY_STORAGE_S3_REGIONENDPOINT forcepathstyle:REGISTRY_STORAGE_S3_FORCEPATHSTYLE secure:REGISTRY_STORAGE_S3_SECURE; do
  value="$(dotenv "${pair#*:}")"
  if [[ -n "$value" ]]; then s3_extra+=$'\n'"    ${pair%%:*}: $value"; fi
done

# Serve blobs through the registry instead of redirecting clients to presigned storage URLs
storage_extra=''
value="$(dotenv REGISTRY_STORAGE_REDIRECT_DISABLE)"
if [[ -n "$value" ]]; then storage_extra=$'\n''  redirect:'$'\n''    disable: '"$value"; fi

config_file="registry-readonly.gc.yml"
override_file="docker-compose.gc-readonly.yml"

cat > "$config_file" <<YML
# Generated by garbage-collect.sh; removed when GC ends. Contains no secrets.
version: 0.1
log:
  level: info
storage:
  cache:
    blobdescriptor: inmemory
  s3:
    bucket: $bucket
    region: $region$s3_extra
  delete:
    enabled: true$storage_extra
  maintenance:
    readonly:
      enabled: true
http:
  addr: :5000
  debug:
    addr: :5001
    prometheus:
      enabled: true
      path: /metrics
health:
  storagedriver:
    enabled: false
YML

cat > "$override_file" <<'YML'
# Generated by garbage-collect.sh; removed when GC ends.
services:
  registry:
    environment: !override
      - REGISTRY_AUTH=htpasswd
      - REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm
      - REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd
      - REGISTRY_STORAGE_S3_ACCESSKEY=${REGISTRY_STORAGE_S3_ACCESSKEY}
      - REGISTRY_STORAGE_S3_SECRETKEY=${REGISTRY_STORAGE_S3_SECRETKEY}
    volumes:
      - ./registry-readonly.gc.yml:/etc/distribution/config.yml:ro
YML

# The container is freshly created, so its whole log is short: look for the line that says it listens.
# (Not the last few lines: debug logging and traffic push that line out of any small window.)
wait_for_registry() {
  local id
  for _ in $(seq 1 20); do
    sleep 2
    id="$("${compose[@]}" ps -q --status running registry 2>/dev/null | head -n1)"
    if [[ -n "$id" ]] && docker logs "$id" 2>&1 | grep -q 'listening on'; then
      return 0
    fi
  done
  return 1
}

reverted=0
revert() {
  [[ "$reverted" -eq 0 ]] || return 0
  reverted=1
  printf '%s\n' 'Putting the registry back in read-write mode...'
  rm -f "$override_file" "$config_file"
  "${compose[@]}" up -d --no-deps registry
  wait_for_registry && printf '%s\n' 'Registry is back to normal.' || printf '%s\n' 'WARNING: registry did not report healthy; check docker compose logs registry.' >&2
  "${compose[@]}" restart ui >/dev/null 2>&1 || true
}
trap revert EXIT HUP INT TERM

printf '%s\n' 'Switching the registry to read-only mode (pushes are rejected until GC ends)...'
"${compose[@]}" -f "$override_file" up -d --no-deps registry
if ! wait_for_registry; then
  printf '%s\n' 'Registry did not start in read-only mode; reverting.' >&2
  exit 1
fi
"${compose[@]}" -f "$override_file" restart ui >/dev/null 2>&1 || true

cid="$("${compose[@]}" ps -q registry)"
if docker exec "$cid" env | grep -q '^REGISTRY_STORAGE=' \
  || ! docker exec "$cid" grep -A2 maintenance /etc/distribution/config.yml | grep -q 'enabled: true'; then
  printf '%s\n' 'Read-only mode is not active in the running registry; refusing to delete anything.' >&2
  exit 1
fi

# The override above is applied by the `-f "$override_file"` argument only to those two commands, so the
# remaining calls (ps/exec) address the already running read-only container.
run_gc_with_retries
printf 'Garbage collection completed. Log: %s\n' "$log_file"
