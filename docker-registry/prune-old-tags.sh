#!/usr/bin/env bash
# Tag retention: keep the newest N tags of every repository and remove the rest.
#
# Only tag links are removed, never manifests, so a versioned tag that points at the same image as
# `latest` cannot take that image with it. Manifests no tag points to any more are collected by
# `garbage-collect.sh --delete --delete-untagged`.
#
# "Newest" is the time the tag was last pushed (the modification time of its tag link in S3). Tags
# matching a --protect pattern never count towards N and are never removed.
#
# Default is a dry run. Nothing is deleted without --delete and a typed confirmation.
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=registry-lib.sh
source ./registry-lib.sh

usage() {
  printf 'Usage: %s [--delete] --keep N [--protect PATTERNS] (REPOSITORY... | --all)\n' "$0"
  printf '\n'
  printf '  --keep N           Keep the N most recently pushed tags of each repository (N >= 1)\n'
  printf '  --protect PATTERNS Comma-separated shell patterns for tags that are never removed and do not\n'
  printf '                     count towards N (default: latest,main). Example: latest,main,v*\n'
  printf '  --all              Every repository\n'
  printf '  --delete           Actually delete (default: dry run)\n'
  printf '  --yes              With --delete: skip the typed DELETE prompt (for runs without a terminal)\n'
}

delete=0
assume_yes=0
all=0
keep=''
protect='latest,main'
repos=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --delete)
      delete=1
      ;;
    --yes)
      assume_yes=1
      ;;
    --all)
      all=1
      ;;
    --keep)
      shift
      keep="${1:-}"
      ;;
    --protect)
      shift
      protect="${1:-}"
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
[[ "$keep" =~ ^[1-9][0-9]*$ ]] || die '--keep N is required and must be a number of at least 1.'
[[ "$protect" =~ ^[A-Za-z0-9._*?,-]*$ ]] || die '--protect takes comma-separated tag patterns (letters, digits, . _ - * ?).'
[[ "$assume_yes" -eq 0 || "$delete" -eq 1 ]] || die '--yes only applies together with --delete.'
[[ "$all" -eq 0 || "${#repos[@]}" -eq 0 ]] || die 'Use --all or a list of repositories, not both.'
if [[ "$all" -eq 0 && "${#repos[@]}" -eq 0 ]]; then
  usage >&2
  exit 2
fi
name_re='^[a-z0-9]+([._-][a-z0-9]+)*(/[a-z0-9]+([._-][a-z0-9]+)*)*$'
for repo in ${repos[@]+"${repos[@]}"}; do
  [[ "$repo" =~ $name_re ]] || die "Invalid repository name: $repo"
done

load_s3_settings
REPOS="${repos[*]:-}"
KEEP="$keep"
PROTECT="$protect"
ALL="$all"
export REPOS KEEP PROTECT ALL

work_init
write_inner_common

cat > "$work/inner.sh" <<'INNER'
set -uo pipefail
cd /work
. /work/common.sh
B="s3://$BUCKET"
ROOT='docker/registry/v2/repositories'

is_protected() { # tag
  local pat
  IFS=',' read -r -a patterns <<< "$PROTECT"
  for pat in "${patterns[@]}"; do
    # shellcheck disable=SC2053 # the unquoted right-hand side is the point: it is a glob pattern
    [[ -n "$pat" && "$1" == $pat ]] && return 0
  done
  return 1
}

ls_retry "$B/$ROOT/" repo_all.raw || { echo 'repository listing failed' >&2; exit 1; }
# repo <TAB> tag <TAB> last push time, from the tag link objects
awk -v root="$ROOT/" '
  $4 ~ /\/_manifests\/tags\/[^\/]+\/current\/link$/ {
    k = $4; sub("^" root, "", k)
    n = index(k, "/_manifests/tags/")
    repo = substr(k, 1, n - 1)
    tag = substr(k, n + 17); sub("/current/link$", "", tag)
    printf "%s\t%s\t%s %s\n", repo, tag, $1, $2
  }' repo_all.raw | sort > tags_all.tsv
if [[ "$ALL" == 1 ]]; then
  cp tags_all.tsv tags.tsv
else
  tr ' ' '\n' <<< "$REPOS" | sed '/^$/d' | sort -u > chosen_repos.txt
  awk -F'\t' 'NR == FNR { r[$1] = 1; next } ($1 in r)' chosen_repos.txt tags_all.tsv > tags.tsv
fi

# newest first within each repository (ties broken by tag name so the result is deterministic)
sort -t$'\t' -k1,1 -k3,3r -k2,2r tags.tsv > sorted.tsv
: > candidates.tsv
prev=''
idx=0
protected=0
while IFS=$'\t' read -r repo tag ts; do
  if [[ "$repo" != "$prev" ]]; then
    prev="$repo"
    idx=0
  fi
  if is_protected "$tag"; then
    protected=$((protected + 1))
    continue
  fi
  idx=$((idx + 1))
  if [[ "$idx" -gt "$KEEP" ]]; then
    printf '%s\t%s\t%s\n' "$repo" "$tag" "$ts" >> candidates.tsv
  fi
done < sorted.tsv

echo "tags examined: $(wc -l < tags.tsv | tr -d ' ')   protected: $protected   keeping the newest $KEEP of the rest per repository"
echo "to remove: $(wc -l < candidates.tsv | tr -d ' ')"
awk -F'\t' '{ print "  DELETE " $1 ":" $2 "  (last pushed " $3 ")" }' candidates.tsv
[[ "$MODE" == exec ]] || exit 0

deleted=0
while IFS=$'\t' read -r repo tag ts; do
  # the listing is a snapshot: a tag pushed again since then is no longer old
  key="$ROOT/$repo/_manifests/tags/$tag/current/link"
  if ! lm="$(aws s3api head-object --bucket "$BUCKET" --key "$key" --query LastModified --output text 2>/dev/null)"; then
    echo "SKIP $repo:$tag: could not confirm its push time"
    continue
  fi
  if [[ "$(date -u -d "$lm" +%s)" -gt $(( $(date -u -d "$ts" +%s) + 1 )) ]]; then
    echo "SKIP $repo:$tag: pushed again since the listing ($lm)"
    continue
  fi
  n="$(rm_retry "$B/$ROOT/$repo/_manifests/tags/$tag/")" || { echo "$repo:$tag: delete failed" >&2; exit 1; }
  deleted=$((deleted + 1))
  echo "DELETED $repo:$tag ($n objects)"
done < candidates.tsv
echo "DELETED $deleted tags"
INNER

run_inner() { # mode
  aws_run inner.sh -e MODE="$1" -e REPOS -e KEEP -e PROTECT -e ALL
}

run_inner plan

[[ -s "$work/candidates.tsv" ]] || { printf '\n%s\n' 'No tags to remove.'; exit 0; }

if [[ "$delete" -eq 0 ]]; then
  printf '\n%s\n' 'Dry run: nothing was deleted. Re-run with --delete to apply.'
  exit 0
fi

printf '\n%s\n' 'WARNING: this permanently removes the tags above (the bucket has no versioning).'
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

printf '\n%s\n' 'Manifests no tag points to any more are removed by: ./garbage-collect.sh --delete --delete-untagged'
