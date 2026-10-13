#!/usr/bin/env bash
# Remove repositories that have no tags (and, separately, dangling tags) from the registry's S3 storage.
#
# The registry keeps listing a repository after its last tag is deleted, because only the tag links
# are removed. This deletes the repository's folder in S3. Layer blobs are shared and stay in the
# bucket until `garbage-collect.sh --delete --delete-untagged` runs.
#
# Two cleanup modes besides removing whole repositories:
#   --dangling-tags    tags whose revision link or manifest blob is missing ("manifest unknown")
#   --dangling-layers  layer links whose blob no longer exists (left behind by garbage collection)
#
# Default is a dry run. Nothing is deleted without --delete and a typed confirmation.
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

usage() {
  printf 'Usage: %s [--delete] REPOSITORY...\n' "$0"
  printf '       %s [--delete] --dangling-tags REPOSITORY\n' "$0"
  printf '       %s [--delete] --dangling-layers (REPOSITORY... | --all)\n' "$0"
  printf '\n'
  printf '  REPOSITORY...      Repositories to remove. Each must have zero tags and contain nothing\n'
  printf '                     but its own _layers, _manifests and _uploads folders (so a repository\n'
  printf '                     with tags, or one that has nested repositories, is refused)\n'
  printf '  --dangling-tags    Remove the tags of one repository whose revision link or manifest blob\n'
  printf '                     is missing (these show as "manifest unknown"). Healthy tags are kept\n'
  printf '  --dangling-layers  Remove layer links whose blob is missing (they point at nothing and are\n'
  printf '                     only clutter). Works on the named repositories, or every repository with\n'
  printf '                     --all. Only _layers/sha256/<digest>/link objects are ever deleted\n'
  printf '  --delete           Actually delete (default: dry run)\n'
  printf '  --yes              With --delete: skip the typed DELETE prompt (for runs without a terminal)\n'
}

delete=0
assume_yes=0
dangling=0
layers=0
all=0
repos=()
for arg in "$@"; do
  case "$arg" in
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
    --all)
      all=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      printf 'Unknown argument: %s\n' "$arg" >&2
      usage >&2
      exit 2
      ;;
    *)
      repos+=("$arg")
      ;;
  esac
done

if [[ "$dangling" -eq 1 && "$layers" -eq 1 ]]; then
  printf '%s\n' 'Use either --dangling-tags or --dangling-layers, not both.' >&2
  exit 2
fi
if [[ "$assume_yes" -eq 1 && "$delete" -eq 0 ]]; then
  printf '%s\n' '--yes only applies together with --delete.' >&2
  exit 2
fi
if [[ "$all" -eq 1 && "$layers" -eq 0 ]]; then
  printf '%s\n' '--all only applies to --dangling-layers.' >&2
  exit 2
fi
if [[ "$all" -eq 1 && "${#repos[@]}" -gt 0 ]]; then
  printf '%s\n' 'Use --all or a list of repositories, not both.' >&2
  exit 2
fi
if [[ "$all" -eq 0 && "${#repos[@]}" -eq 0 ]]; then
  usage >&2
  exit 2
fi
if [[ "$dangling" -eq 1 && "${#repos[@]}" -ne 1 ]]; then
  printf '%s\n' '--dangling-tags takes exactly one repository.' >&2
  exit 2
fi
# Repository names follow the registry's own grammar; this also rules out empty parts and "..".
name_re='^[a-z0-9]+([._-][a-z0-9]+)*(/[a-z0-9]+([._-][a-z0-9]+)*)*$'
for repo in "${repos[@]}"; do
  if ! [[ "$repo" =~ $name_re ]]; then
    printf 'Invalid repository name: %s\n' "$repo" >&2
    exit 2
  fi
done

cid="$(docker ps -q \
  --filter "label=com.docker.compose.project.working_dir=$PWD" \
  --filter "label=com.docker.compose.service=registry" | head -n1)"
if [[ -z "$cid" ]]; then
  printf '%s\n' 'Registry container is not running; cannot read the S3 settings.' >&2
  exit 1
fi

container_env() {
  docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$cid" | sed -n "s/^$1=//p" | head -n1
}
dotenv() {
  [[ -f .env ]] && sed -n "s/^$1=//p" .env | head -n1 || true
}
setting() {
  local value
  value="$(container_env "$1")"
  [[ -n "$value" ]] || value="$(dotenv "$1")"
  printf '%s' "$value"
}

AWS_ACCESS_KEY_ID="$(setting REGISTRY_STORAGE_S3_ACCESSKEY)"
AWS_SECRET_ACCESS_KEY="$(setting REGISTRY_STORAGE_S3_SECRETKEY)"
AWS_DEFAULT_REGION="$(setting REGISTRY_STORAGE_S3_REGION)"
BUCKET="$(setting REGISTRY_STORAGE_S3_BUCKET)"
REPOS="${repos[*]:-}"
DANGLING="$dangling"
LAYERS="$layers"
ALL="$all"
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION BUCKET REPOS DANGLING LAYERS ALL

if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" || -z "$BUCKET" ]]; then
  printf '%s\n' 'Missing S3 settings (access key, secret key or bucket).' >&2
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cat > "$work/inner.sh" <<'INNER'
set -uo pipefail
cd /work
B="s3://$BUCKET"
ROOT='docker/registry/v2/repositories'

ls_retry() { # prefix, output file
  local i rc
  for i in 1 2 3 4 5 6; do
    rc=0
    aws s3 ls "$1" --recursive > "$2" 2> "$2.err" || rc=$?
    [[ "$rc" -eq 0 ]] && return 0
    # `aws s3 ls` exits 1 with no output and no error text when the prefix is simply empty
    [[ "$rc" -eq 1 && ! -s "$2.err" ]] && return 0
    echo "listing $1 failed (exit $rc, attempt $i), retrying" >&2
    sleep 5
  done
  return 1
}
cp_retry() {
  local i
  for i in 1 2 3; do
    aws s3 cp "$1" - 2>/dev/null && return 0
    sleep 2
  done
  return 1
}
rm_retry() { # prefix; prints the number of deleted objects
  local i out
  for i in 1 2 3; do
    out="$(aws s3 rm "$1" --recursive 2>/dev/null)" && { echo "$out" | grep -c '^delete:'; return 0; }
    sleep 3
  done
  return 1
}

# head-object on one exact key: returns 0 = exists, 1 = confirmed missing, 2 = could not tell.
# Used to re-check candidates live, because a push between the listing and the tag read would
# otherwise make a brand-new tag look dangling.
s3_state() {
  local i out
  for i in 1 2 3; do
    out="$(aws s3api head-object --bucket "$BUCKET" --key "$1" 2>&1)" && return 0
    grep -qE 'Not Found|404|NoSuchKey' <<< "$out" && return 1
    sleep 2
  done
  return 2
}

# Lists one repository's keys relative to its folder into keys.txt; returns 1 if S3 keeps failing.
load_repo() {
  ls_retry "$B/$ROOT/$1/" repo.raw || return 1
  awk '{print $4}' repo.raw | sed "s#^$ROOT/$1/##" > keys.txt
}

# ---------------------------------------------------------------- empty repositories
plan_repo() {
  local repo="$1" total tags revs other dry
  load_repo "$repo" || { echo "$repo: S3 listing failed" >&2; return 1; }
  total="$(wc -l < keys.txt | tr -d ' ')"
  if [[ "$total" -eq 0 ]]; then
    echo "SKIP $repo: nothing found under that name"
    return 0
  fi
  tags="$(grep -c '^_manifests/tags/' keys.txt || true)"
  revs="$(grep -c '^_manifests/revisions/' keys.txt || true)"
  # anything outside the three expected folders is another repository nested below this one
  other="$(grep -vc -E '^(_layers|_manifests|_uploads)/' keys.txt || true)"
  if [[ "$tags" -ne 0 ]]; then
    echo "SKIP $repo: has $tags tag objects"
  elif [[ "$other" -ne 0 ]]; then
    echo "SKIP $repo: $other objects outside _layers/_manifests/_uploads (nested repository?)"
  else
    dry="$(aws s3 rm "$B/$ROOT/$repo/" --recursive --dryrun 2>/dev/null | grep -c '(dryrun) delete:')"
    if [[ "$dry" -ne "$total" ]]; then
      echo "SKIP $repo: dry run counts $dry objects but listing shows $total"
    else
      echo "OK   $repo: $total objects ($revs untagged revisions, 0 tags)"
      echo "$repo" >> eligible.txt
    fi
  fi
}

run_repos() {
  local repo n left
  if [[ "$MODE" == plan ]]; then
    : > eligible.txt
    for repo in $REPOS; do plan_repo "$repo" || exit 1; done
    return 0
  fi
  while read -r repo; do
    [[ -n "$repo" ]] || continue
    load_repo "$repo" || { echo "$repo: S3 listing failed, not deleting" >&2; exit 1; }
    if [[ "$(grep -c '^_manifests/tags/' keys.txt || true)" -ne 0 ]]; then
      echo "SKIP $repo: a tag appeared since the plan"
      continue
    fi
    n="$(rm_retry "$B/$ROOT/$repo/")" || { echo "$repo: delete failed" >&2; exit 1; }
    left="$(aws s3 ls "$B/$ROOT/$repo/" --recursive 2>/dev/null | wc -l | tr -d ' ')"
    echo "DELETED $repo: $n objects removed, $left remaining"
  done < eligible.txt
}

# ---------------------------------------------------------------- dangling tags
run_dangling() {
  local repo="$REPOS" tag d n=0
  ls_retry "$B/docker/registry/v2/blobs/sha256/" blobs.raw || { echo 'blob listing failed' >&2; exit 1; }
  awk '{n=split($4,p,"/"); print p[n-1]}' blobs.raw | sort -u > blobs.txt
  load_repo "$repo" || { echo 'repository listing failed' >&2; exit 1; }
  : > dangling_tags.txt
  while read -r tag; do
    d="$(cp_retry "$B/$ROOT/$repo/_manifests/tags/$tag/current/link")"
    d="${d#sha256:}"
    if [[ -z "$d" ]]; then
      echo "$tag: tag link unreadable, leaving it alone" >&2
      continue
    fi
    # A tag is only dangling if S3 confirms (head-object) that its revision link or manifest blob is
    # missing: the listings are a snapshot, and a push in between creates tags they do not know yet.
    rev=0; blob=0
    grep -qxF "_manifests/revisions/sha256/$d/link" keys.txt || { s3_state "$ROOT/$repo/_manifests/revisions/sha256/$d/link"; rev=$?; }
    grep -qxF "$d" blobs.txt || { s3_state "docker/registry/v2/blobs/sha256/${d:0:2}/$d/data"; blob=$?; }
    if [[ "$rev" -eq 2 || "$blob" -eq 2 ]]; then
      echo "$tag: could not verify against S3, leaving it alone" >&2
    elif [[ "$rev" -eq 1 || "$blob" -eq 1 ]]; then
      echo "$tag" >> dangling_tags.txt
    fi
  done < <(grep -E '^_manifests/tags/[^/]+/current/link$' keys.txt | sed -E 's#^_manifests/tags/([^/]+)/current/link$#\1#')
  echo "$repo: $(grep -c '/current/link$' keys.txt || true) tags, $(wc -l < dangling_tags.txt | tr -d ' ') dangling"
  sed 's/^/  dangling: /' dangling_tags.txt
  [[ "$MODE" == exec ]] || return 0
  while read -r tag; do
    [[ -n "$tag" ]] || continue
    n=$((n + $(rm_retry "$B/$ROOT/$repo/_manifests/tags/$tag/") ))
  done < dangling_tags.txt
  echo "DELETED $n tag objects"
}

# ---------------------------------------------------------------- dangling layer links
run_layers() {
  local n i total dang batch deleted errs out lines step
  # Order matters. Repository keys are listed FIRST and blobs AFTER (twice, union): a push writes the
  # blob before its link, so a link seen in the first listing always has its blob in the later ones.
  ls_retry "$B/$ROOT/" repo_all.raw || { echo 'repository listing failed' >&2; exit 1; }
  awk '{print $4}' repo_all.raw | sed "s#^$ROOT/##" > keys.txt
  ls_retry "$B/docker/registry/v2/blobs/sha256/" blobs1.raw || { echo 'blob listing failed' >&2; exit 1; }
  ls_retry "$B/docker/registry/v2/blobs/sha256/" blobs2.raw || { echo 'blob listing failed' >&2; exit 1; }
  cat blobs1.raw blobs2.raw | awk '{n=split($4,p,"/"); print p[n-1]}' | sort -u > blobs.txt
  if [[ ! -s blobs.txt ]]; then
    echo 'No blobs found in the bucket; refusing (everything would look dangling).' >&2
    exit 1
  fi

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
  awk -v s="$step" 'NR % s == 1' dangling.tsv | head -25 > sample.tsv
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
  docker run --rm \
    -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION -e BUCKET -e REPOS -e DANGLING -e LAYERS -e ALL \
    -e "MODE=$1" -v "$work:/work" --entrypoint bash amazon/aws-cli /work/inner.sh
}

run_inner plan

if [[ "$layers" -eq 1 ]]; then
  [[ -s "$work/dangling.tsv" ]] || { printf '\n%s\n' 'No dangling layer links.'; exit 0; }
elif [[ "$dangling" -eq 1 ]]; then
  [[ -s "$work/dangling_tags.txt" ]] || { printf '\n%s\n' 'No dangling tags.'; exit 0; }
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
