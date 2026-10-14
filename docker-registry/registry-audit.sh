#!/usr/bin/env bash
# Read-only audit of the registry's S3 storage.
#
# Reports, per repository: tags, manifest revisions and layer links. Flags zero-tag repositories and
# dangling tags (a tag whose revision link or manifest blob is missing, which shows up as
# "manifest unknown" in the UI). With --verify-refs it also checks that every blob referenced by a
# live manifest exists. Nothing is modified.
#
# Exit status:   0  nothing wrong
#               10  only dangling tags, which prune-empty-repos.sh --dangling-tags can remove
#               20  a live image references blobs that are missing (nothing can repair this)
#                1  the audit could not complete (S3 errors, tags that could not be verified)
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=registry-lib.sh
source ./registry-lib.sh

usage() {
  printf 'Usage: %s [--verify-refs]\n' "$0"
  printf '\n'
  printf '  --verify-refs  Also check that every blob referenced by a live manifest exists (slower)\n'
  printf '\n'
  printf 'Exit status: 0 clean, 10 dangling tags only, 20 live image with missing blobs, 1 incomplete\n'
}

verify_refs=0
for arg in "$@"; do
  case "$arg" in
    --verify-refs)
      verify_refs=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

load_s3_settings
VERIFY_REFS="$verify_refs"
export VERIFY_REFS

work_init
write_inner_common

cat > "$work/audit.sh" <<'INNER'
set -uo pipefail
cd /work
. /work/common.sh
B="s3://$BUCKET/docker/registry/v2"
PREFIX='docker/registry/v2/repositories/'

ls_retry "$B/repositories/" repos.raw || { echo 'Could not list repositories (S3 errors).' >&2; exit 1; }
ls_retry "$B/blobs/sha256/" blobs.raw || { echo 'Could not list blobs (S3 errors).' >&2; exit 1; }
awk '{print $4}' repos.raw > keys.txt
awk '{n=split($4,p,"/"); print p[n-1]}' blobs.raw | sort -u > blobs.txt

echo "Storage: $(wc -l < keys.txt | tr -d ' ') repository objects; $(awk '{s+=$3} END{printf "%d blobs, %.2f GiB", NR, s/2^30}' blobs.raw)"
echo

awk -v prefix="$PREFIX" '
  {
    k = $0; sub("^" prefix, "", k)
    i = index(k, "/_"); if (!i) next
    r = substr(k, 1, i - 1); rest = substr(k, i + 1); seen[r] = 1
    if (rest ~ /^_manifests\/tags\/[^\/]+\/current\/link$/) t[r]++
    else if (rest ~ /^_manifests\/revisions\/sha256\/[0-9a-f]+\/link$/) m[r]++
    else if (rest ~ /^_layers\/sha256\/[0-9a-f]+\/link$/) l[r]++
  }
  END { for (r in seen) printf "%s\t%d\t%d\t%d\n", r, t[r] + 0, m[r] + 0, l[r] + 0 }
' keys.txt | sort > repos.tsv

printf '%-55s %6s %10s %12s\n' REPOSITORY TAGS REVISIONS LAYER-LINKS
while IFS=$'\t' read -r repo tags revs layers; do
  flag=''
  [[ "$tags" -eq 0 ]] && flag='  <- no tags'
  printf '%-55s %6d %10d %12d%s\n' "$repo" "$tags" "$revs" "$layers" "$flag"
done < repos.tsv
echo
echo "Zero-tag repositories: $(awk -F'\t' '$2 == 0' repos.tsv | wc -l | tr -d ' ')"

grep -E '/_manifests/tags/[^/]+/current/link$' keys.txt \
  | sed -E "s#^${PREFIX}(.*)/_manifests/tags/([^/]+)/current/link\$#\\1\\t\\2#" | sort > tags.tsv

: > dangling.txt
: > unverified.txt
: > live.txt
while IFS=$'\t' read -r repo tag; do
  d="$(cp_retry "$B/repositories/$repo/_manifests/tags/$tag/current/link")"
  d="${d#sha256:}"
  if [[ -z "$d" ]]; then
    echo "$repo:$tag -> tag link unreadable" >> unverified.txt
    continue
  fi
  # the listings are a snapshot; anything missing from them is re-checked directly in S3
  rev_key="${PREFIX}${repo}/_manifests/revisions/sha256/$d/link"
  blob_key="docker/registry/v2/blobs/sha256/${d:0:2}/$d/data"
  rev=0; blob=0
  grep -qxF "$rev_key" keys.txt || { s3_state "$rev_key"; rev=$?; }
  grep -qxF "$d" blobs.txt || { s3_state "$blob_key"; blob=$?; }
  if [[ "$rev" -eq 1 ]]; then
    echo "$repo:$tag -> no revision link in this repository (sha256:${d:0:12})" >> dangling.txt
  elif [[ "$blob" -eq 1 ]]; then
    echo "$repo:$tag -> manifest blob missing (sha256:${d:0:12})" >> dangling.txt
  elif [[ "$rev" -eq 2 || "$blob" -eq 2 ]]; then
    echo "$repo:$tag -> could not verify against S3 (sha256:${d:0:12})" >> unverified.txt
  else
    echo "$d" >> live.txt
  fi
done < tags.tsv

echo "Tags checked: $(wc -l < tags.tsv | tr -d ' ')   dangling: $(wc -l < dangling.txt | tr -d ' ')   unverified: $(wc -l < unverified.txt | tr -d ' ')"
if [[ -s dangling.txt ]]; then
  echo 'Dangling tags:'
  sed 's/^/  /' dangling.txt
fi
if [[ -s unverified.txt ]]; then
  echo 'Tags that could not be verified:'
  sed 's/^/  /' unverified.txt
fi

missing=0
if [[ "$VERIFY_REFS" == 1 ]]; then
  # Walk down from every live tag's manifest. An index lists child manifests (followed); an image
  # manifest lists its config and layers (checked for existence, never opened: a config holds
  # diff_ids, which are not blobs in the registry).
  sort -u live.txt > todo.txt
  : > seen.txt
  : > refs.txt
  : > unreadable.txt
  while [[ -s todo.txt ]]; do
    : > next.txt
    while read -r d; do
      grep -qxF "$d" seen.txt && continue
      echo "$d" >> seen.txt
      if ! cp_retry "$B/blobs/sha256/${d:0:2}/$d/data" > one.json; then
        echo "$d" >> unreadable.txt
        continue
      fi
      grep -o 'sha256:[0-9a-f]\{64\}' one.json | sed 's/^sha256://' | sort -u > one.txt
      cat one.txt >> refs.txt
      if grep -q '"manifests"' one.json; then cat one.txt >> next.txt; fi
    done < todo.txt
    sort -u next.txt > todo.txt
  done
  sort -u refs.txt > refs_u.txt
  comm -23 refs_u.txt blobs.txt > missing.txt
  missing="$(wc -l < missing.txt | tr -d ' ')"
  echo "Live manifests walked: $(wc -l < seen.txt | tr -d ' ')   blobs referenced: $(wc -l < refs_u.txt | tr -d ' ')   referenced but missing: $missing"
  if [[ "$missing" -gt 0 ]]; then sed 's/^/  missing: sha256:/' missing.txt | head -20; fi
  if [[ -s unreadable.txt ]]; then
    echo "Manifests that could not be read: $(wc -l < unreadable.txt | tr -d ' ')"
    cat unreadable.txt >> unverified.txt
  fi
fi

# most serious first
if [[ "$missing" -gt 0 ]]; then exit 20; fi
if [[ -s unverified.txt ]]; then exit 1; fi
if [[ -s dangling.txt ]]; then exit 10; fi
exit 0
INNER

rc=0
aws_run audit.sh -e VERIFY_REFS || rc=$?
case "$rc" in
  0)
    printf '\n%s\n' 'Audit finished: no problems found.'
    ;;
  10)
    printf '\n%s\n' 'Audit finished: dangling tags found (prune-empty-repos.sh --dangling-tags can remove them).' >&2
    ;;
  20)
    printf '\n%s\n' 'Audit finished: a live image references blobs that no longer exist.' >&2
    ;;
  *)
    printf '\n%s\n' 'Audit could not complete or verify everything (see above).' >&2
    rc=1
    ;;
esac
exit "$rc"
