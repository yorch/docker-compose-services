#!/usr/bin/env bash
# Remove repositories that have no tags (and, separately, dangling tags and layer links) from the
# registry's S3 storage.
#
# The registry keeps listing a repository after its last tag is deleted, because only the tag links
# are removed. This deletes the repository's folder in S3. Layer blobs are shared and stay in the
# bucket until `garbage-collect.sh --delete --delete-untagged` runs.
#
# Modes:
#   REPOSITORY...      remove these repositories (each must have no tags)
#   --empty            remove every repository that has no tags
#   --dangling-tags    remove tags whose revision link or manifest blob is missing ("manifest unknown")
#   --dangling-layers  remove layer links whose blob no longer exists (left behind by garbage collection)
#
# Default is a dry run. Nothing is deleted without --delete and a typed confirmation.
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=registry-lib.sh
source ./registry-lib.sh

usage() {
  printf 'Usage: %s [--delete] [--min-age HOURS] REPOSITORY...\n' "$0"
  printf '       %s [--delete] [--min-age HOURS] --empty\n' "$0"
  printf '       %s [--delete] --dangling-tags (REPOSITORY... | --all)\n' "$0"
  printf '       %s [--delete] --dangling-layers (REPOSITORY... | --all)\n' "$0"
  printf '\n'
  printf '  REPOSITORY...      Repositories to remove. Each must have zero tags and contain nothing\n'
  printf '                     but its own _layers, _manifests and _uploads folders (so a repository\n'
  printf '                     with tags, or one that has nested repositories, is refused)\n'
  printf '  --empty            Find and remove every repository that has no tags\n'
  printf '  --min-age HOURS    Leave repositories alone that had any activity in the last HOURS hours.\n'
  printf '                     A repository mid-way through its first push has layers but no tags yet\n'
  printf '  --dangling-tags    Remove tags whose revision link or manifest blob is missing (these show\n'
  printf '                     as "manifest unknown"). Healthy tags are kept\n'
  printf '  --dangling-layers  Remove layer links whose blob is missing (they point at nothing and are\n'
  printf '                     only clutter). Only _layers/sha256/<digest>/link objects are ever deleted\n'
  printf '  --all              With --dangling-tags/--dangling-layers: every repository\n'
  printf '  --delete           Actually delete (default: dry run)\n'
  printf '  --yes              With --delete: skip the typed DELETE prompt (for runs without a terminal)\n'
}

delete=0
assume_yes=0
dangling=0
layers=0
empty=0
all=0
min_age=0
repos=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --delete)
      delete=1
      ;;
    --yes)
      assume_yes=1
      ;;
    --dangling-tags)
      dangling=1
      ;;
    --dangling-layers)
      layers=1
      ;;
    --empty)
      empty=1
      ;;
    --all)
      all=1
      ;;
    --min-age)
      shift
      min_age="${1:-}"
      [[ "$min_age" =~ ^[0-9]+$ ]] || { printf '%s\n' '--min-age needs a number of hours.' >&2; exit 2; }
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
    *)
      repos+=("$1")
      ;;
  esac
  shift
done

die() {
  printf '%s\n' "$1" >&2
  exit 2
}
modes=$((dangling + layers + empty))
[[ "$modes" -le 1 ]] || die 'Use only one of --empty, --dangling-tags and --dangling-layers.'
[[ "$assume_yes" -eq 0 || "$delete" -eq 1 ]] || die '--yes only applies together with --delete.'
[[ "$all" -eq 0 || "$dangling" -eq 1 || "$layers" -eq 1 ]] || die '--all only applies to --dangling-tags and --dangling-layers.'
[[ "$all" -eq 0 || "${#repos[@]}" -eq 0 ]] || die 'Use --all or a list of repositories, not both.'
[[ "$min_age" -eq 0 || "$dangling" -eq 0 && "$layers" -eq 0 ]] || die '--min-age only applies to removing repositories.'
if [[ "$empty" -eq 1 ]]; then
  [[ "${#repos[@]}" -eq 0 ]] || die '--empty finds the repositories itself; do not name any.'
elif [[ "$all" -eq 0 && "${#repos[@]}" -eq 0 ]]; then
  usage >&2
  exit 2
fi
# Repository names follow the registry's own grammar; this also rules out empty parts and "..".
name_re='^[a-z0-9]+([._-][a-z0-9]+)*(/[a-z0-9]+([._-][a-z0-9]+)*)*$'
for repo in ${repos[@]+"${repos[@]}"}; do
  [[ "$repo" =~ $name_re ]] || die "Invalid repository name: $repo"
done

load_s3_settings
REPOS="${repos[*]:-}"
DANGLING="$dangling"
LAYERS="$layers"
EMPTY="$empty"
ALL="$all"
MIN_AGE_HOURS="$min_age"
export REPOS DANGLING LAYERS EMPTY ALL MIN_AGE_HOURS

work_init
write_inner_common

cat > "$work/inner.sh" <<'INNER'
set -uo pipefail
cd /work
. /work/common.sh
B="s3://$BUCKET"
ROOT='docker/registry/v2/repositories'

# Lists one repository's keys relative to its folder into keys.txt (timestamps stay in repo.raw);
# returns 1 if S3 keeps failing.
load_repo() {
  ls_retry "$B/$ROOT/$1/" repo.raw || return 1
  awk '{print $4}' repo.raw | sed "s#^$ROOT/$1/##" > keys.txt
}

# Every key under repositories/, relative to it, into keys.txt. Always listed BEFORE the blobs (see
# list_blobs): a push writes the blob before its link, so a link in this listing has its blob in the
# later one.
list_all_keys() {
  ls_retry "$B/$ROOT/" repo_all.raw || { echo 'repository listing failed' >&2; exit 1; }
  awk '{print $4}' repo_all.raw | sed "s#^$ROOT/##" > keys.txt
}
list_blobs() { # blobs.txt: every digest present, from two listings (union)
  ls_retry "$B/docker/registry/v2/blobs/sha256/" blobs1.raw || { echo 'blob listing failed' >&2; exit 1; }
  ls_retry "$B/docker/registry/v2/blobs/sha256/" blobs2.raw || { echo 'blob listing failed' >&2; exit 1; }
  cat blobs1.raw blobs2.raw | awk '{n=split($4,p,"/"); print p[n-1]}' | sort -u > blobs.txt
  if [[ ! -s blobs.txt ]]; then
    echo 'No blobs found in the bucket; refusing (everything would look dangling).' >&2
    exit 1
  fi
}

# ---------------------------------------------------------------- empty repositories
# Returns 0 and prints "OK ..." when the repository may be removed, 1 (printing why) otherwise.
check_repo() {
  local repo="$1" total tags revs other dry newest age
  load_repo "$repo" || { echo "$repo: S3 listing failed" >&2; return 1; }
  total="$(wc -l < keys.txt | tr -d ' ')"
  if [[ "$total" -eq 0 ]]; then
    echo "SKIP $repo: nothing found under that name"
    return 1
  fi
  tags="$(grep -c '^_manifests/tags/' keys.txt || true)"
  revs="$(grep -c '^_manifests/revisions/' keys.txt || true)"
  # anything outside the three expected folders is another repository nested below this one
  other="$(grep -vc -E '^(_layers|_manifests|_uploads)/' keys.txt || true)"
  if [[ "$tags" -ne 0 ]]; then
    echo "SKIP $repo: has $tags tag objects"
    return 1
  elif [[ "$other" -ne 0 ]]; then
    echo "SKIP $repo: $other objects outside _layers/_manifests/_uploads (nested repository?)"
    return 1
  fi
  if [[ "${MIN_AGE_HOURS:-0}" -gt 0 ]]; then
    newest="$(awk '{print $1" "$2}' repo.raw | sort | tail -1)"
    age=$(( ( $(date -u +%s) - $(date -u -d "$newest" +%s) ) / 3600 ))
    if [[ "$age" -lt "$MIN_AGE_HOURS" ]]; then
      echo "SKIP $repo: last activity ${age}h ago (minimum age ${MIN_AGE_HOURS}h)"
      return 1
    fi
  fi
  dry="$(aws s3 rm "$B/$ROOT/$repo/" --recursive --dryrun 2>/dev/null | grep -c '(dryrun) delete:')"
  if [[ "$dry" -ne "$total" ]]; then
    echo "SKIP $repo: dry run counts $dry objects but listing shows $total"
    return 1
  fi
  echo "OK   $repo: $total objects ($revs untagged revisions, 0 tags)"
}

discover_empty() { # repos_empty.txt: repositories without any tag object
  list_all_keys
  sed -nE 's#^(.*)/_(layers|manifests|uploads)/.*#\1#p' keys.txt | sort -u > repos_all.txt
  grep '/_manifests/tags/' keys.txt | sed -E 's#^(.*)/_manifests/tags/.*#\1#' | sort -u > repos_tagged.txt
  comm -23 repos_all.txt repos_tagged.txt > repos_empty.txt
  echo "repositories: $(wc -l < repos_all.txt | tr -d ' ')   without tags: $(wc -l < repos_empty.txt | tr -d ' ')"
}

run_repos() {
  local repo n left
  if [[ "$MODE" == plan ]]; then
    : > eligible.txt
    if [[ "$EMPTY" == 1 ]]; then discover_empty; REPOS="$(tr '\n' ' ' < repos_empty.txt)"; fi
    for repo in $REPOS; do
      if check_repo "$repo"; then echo "$repo" >> eligible.txt; fi
    done
    return 0
  fi
  # delete phase: everything is checked again, since a tag may have appeared since the plan
  while read -r repo; do
    [[ -n "$repo" ]] || continue
    if ! check_repo "$repo"; then continue; fi
    n="$(rm_retry "$B/$ROOT/$repo/")" || { echo "$repo: delete failed" >&2; exit 1; }
    left="$(aws s3 ls "$B/$ROOT/$repo/" --recursive 2>/dev/null | wc -l | tr -d ' ')"
    echo "DELETED $repo: $n objects removed, $left remaining"
  done < eligible.txt
}

# ---------------------------------------------------------------- dangling tags
run_dangling() {
  local repo tag d rev blob n=0
  list_all_keys
  list_blobs
  sed -nE 's#^(.*)/_manifests/tags/([^/]+)/current/link$#\1\t\2#p' keys.txt | sort > tags_all.tsv
  if [[ "$ALL" == 1 ]]; then
    cp tags_all.tsv tags.tsv
  else
    tr ' ' '\n' <<< "$REPOS" | sed '/^$/d' | sort -u > chosen_repos.txt
    awk -F'\t' 'NR == FNR { r[$1] = 1; next } ($1 in r)' chosen_repos.txt tags_all.tsv > tags.tsv
  fi
  : > dangling_tags.tsv
  while IFS=$'\t' read -r repo tag; do
    d="$(cp_retry "$B/$ROOT/$repo/_manifests/tags/$tag/current/link")"
    d="${d#sha256:}"
    if [[ -z "$d" ]]; then
      echo "$repo:$tag: tag link unreadable, leaving it alone" >&2
      continue
    fi
    # A tag is only dangling if S3 confirms (head-object) that its revision link or manifest blob is
    # missing: the listings are a snapshot, and a push in between creates tags they do not know yet.
    rev=0; blob=0
    grep -qxF "$repo/_manifests/revisions/sha256/$d/link" keys.txt || { s3_state "$ROOT/$repo/_manifests/revisions/sha256/$d/link"; rev=$?; }
    grep -qxF "$d" blobs.txt || { s3_state "docker/registry/v2/blobs/sha256/${d:0:2}/$d/data"; blob=$?; }
    if [[ "$rev" -eq 2 || "$blob" -eq 2 ]]; then
      echo "$repo:$tag: could not verify against S3, leaving it alone" >&2
    elif [[ "$rev" -eq 1 || "$blob" -eq 1 ]]; then
      printf '%s\t%s\n' "$repo" "$tag" >> dangling_tags.tsv
    fi
  done < tags.tsv
  echo "tags examined: $(wc -l < tags.tsv | tr -d ' ')   dangling: $(wc -l < dangling_tags.tsv | tr -d ' ')"
  awk -F'\t' '{ print "  dangling: " $1 ":" $2 }' dangling_tags.tsv
  [[ "$MODE" == exec ]] || return 0
  while IFS=$'\t' read -r repo tag; do
    n=$((n + $(rm_retry "$B/$ROOT/$repo/_manifests/tags/$tag/") ))
  done < dangling_tags.tsv
  echo "DELETED $n tag objects"
}

# ---------------------------------------------------------------- dangling layer links
run_layers() {
  local i total batch deleted errs out lines step
  list_all_keys
  list_blobs

  sed -nE 's#^(.*)/_layers/sha256/([0-9a-f]{64})/link$#\1\t\2#p' keys.txt | sort > links.tsv
  if [[ "$ALL" == 1 ]]; then
    cp links.tsv chosen.tsv
  else
    tr ' ' '\n' <<< "$REPOS" | sed '/^$/d' | sort -u > chosen_repos.txt
    awk -F'\t' 'NR == FNR { r[$1] = 1; next } ($1 in r)' chosen_repos.txt links.tsv > chosen.tsv
  fi
  awk -F'\t' 'NR == FNR { b[$1] = 1; next } !($2 in b)' blobs.txt chosen.tsv > dangling.tsv

  echo "blobs in bucket: $(wc -l < blobs.txt | tr -d ' ')   layer links examined: $(wc -l < chosen.tsv | tr -d ' ')"
  awk -F'\t' 'NR == FNR { b[$1] = 1; next } { t[$1]++; if (!($2 in b)) d[$1]++; seen[$1] = 1 }
    END { for (r in seen) printf "%-55s %6d dangling of %6d layer links\n", r, d[r] + 0, t[r] }' blobs.txt chosen.tsv | sort
  total="$(wc -l < dangling.tsv | tr -d ' ')"
  echo "TOTAL dangling layer links: $total"
  [[ "$total" -gt 0 ]] || return 0

  # Independent check against S3 itself: a sample of the "missing" blobs must really be missing.
  step=$(( total / 25 + 1 ))
  awk -v s="$step" 'NR % s == 0' dangling.tsv | head -25 > sample.tsv
  while IFS=$'\t' read -r repo d; do
    if out="$(aws s3api head-object --bucket "$BUCKET" --key "docker/registry/v2/blobs/sha256/${d:0:2}/$d/data" 2>&1)"; then
      echo "ABORT: blob sha256:${d:0:12} (layer link in $repo) exists in S3 although the listing did not show it" >&2
      exit 1
    fi
    if ! grep -qE 'Not Found|404|NoSuchKey' <<< "$out"; then
      echo "ABORT: could not confirm that blob sha256:${d:0:12} is missing: ${out:0:120}" >&2
      exit 1
    fi
  done < sample.tsv
  echo "Spot check: $(wc -l < sample.tsv | tr -d ' ') of the dangling candidates confirmed missing directly in S3."
  [[ "$MODE" == exec ]] || return 0

  # Delete in batches of 1000 keys (the S3 limit). Only _layers/sha256/<digest>/link objects are named.
  awk -F'\t' -v root="$ROOT" '{ printf "%s/%s/_layers/sha256/%s/link\n", root, $1, $2 }' dangling.tsv > delete_keys.txt
  split -l 1000 delete_keys.txt batch_
  deleted=0
  for batch in batch_*; do
    awk 'BEGIN { printf "{\"Quiet\": false, \"Objects\": [" } { printf "%s{\"Key\": \"%s\"}", (NR > 1 ? "," : ""), $0 } END { printf "]}" }' "$batch" > "$batch.json"
    for i in 1 2 3; do
      out="$(aws s3api delete-objects --bucket "$BUCKET" --delete "file://$batch.json" --output json 2>/dev/null)" && break
      out=''
      sleep 3
    done
    [[ -n "$out" ]] || { echo "delete batch $batch failed after retries; stopping (re-run to continue)" >&2; exit 1; }
    errs="$(grep -c '"Code"' <<< "$out" || true)"
    lines="$(grep -c '"Key"' <<< "$out" || true)"
    deleted=$((deleted + lines - errs))
    [[ "$errs" -eq 0 ]] || { echo "S3 reported $errs errors in batch $batch; stopping" >&2; exit 1; }
  done
  echo "DELETED $deleted dangling layer links"
}

if [[ "$LAYERS" == 1 ]]; then run_layers; elif [[ "$DANGLING" == 1 ]]; then run_dangling; else run_repos; fi
INNER

run_inner() { # mode
  aws_run inner.sh -e MODE="$1" -e REPOS -e DANGLING -e LAYERS -e EMPTY -e ALL -e MIN_AGE_HOURS
}

run_inner plan

if [[ "$layers" -eq 1 ]]; then
  [[ -s "$work/dangling.tsv" ]] || { printf '\n%s\n' 'No dangling layer links.'; exit 0; }
elif [[ "$dangling" -eq 1 ]]; then
  [[ -s "$work/dangling_tags.tsv" ]] || { printf '\n%s\n' 'No dangling tags.'; exit 0; }
else
  [[ -s "$work/eligible.txt" ]] || { printf '\n%s\n' 'Nothing eligible to delete.'; exit 0; }
fi

if [[ "$delete" -eq 0 ]]; then
  printf '\n%s\n' 'Dry run: nothing was deleted. Re-run with --delete to apply.'
  exit 0
fi

printf '\n%s\n' 'WARNING: this permanently deletes the objects above from S3 (the bucket has no versioning).'
if [[ "$assume_yes" -eq 1 ]]; then
  printf '%s\n' '--yes given: continuing without the typed confirmation.'
else
  read -r -p 'Type DELETE to continue: ' confirmation || confirmation=''
  [[ "$confirmation" == "DELETE" ]] || {
    printf '%s\n' 'Cancelled.'
    exit 1
  }
fi

run_inner exec

if [[ "$dangling" -eq 0 && "$layers" -eq 0 ]]; then
  printf '\n%s\n' 'Blobs stay in the bucket until: ./garbage-collect.sh --delete --delete-untagged'
fi
