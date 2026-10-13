#!/usr/bin/env bash
# Read-only audit of the registry's S3 storage.
#
# Reports, per repository: tags, manifest revisions and layer links. Flags zero-tag repositories and
# dangling tags (a tag whose revision link or manifest blob is missing, which shows up as
# "manifest unknown" in the UI). With --verify-refs it also checks that every blob referenced by a
# live manifest exists. Nothing is modified.
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

usage() {
  printf 'Usage: %s [--verify-refs]\n' "$0"
  printf '\n'
  printf '  --verify-refs  Also check that every blob referenced by a live manifest exists (slower)\n'
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

cid="$(docker ps -q \
  --filter "label=com.docker.compose.project.working_dir=$PWD" \
  --filter "label=com.docker.compose.service=registry" | head -n1)"
if [[ -z "$cid" ]]; then
  printf '%s\n' 'Registry container is not running; cannot read the S3 settings.' >&2
  exit 1
fi

# Settings come from the running container (falling back to .env); credentials are exported so
# `docker run -e VAR` passes them without putting them on a command line or on disk.
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
VERIFY_REFS="$verify_refs"
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION BUCKET VERIFY_REFS

if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" || -z "$BUCKET" ]]; then
  printf '%s\n' 'Missing S3 settings (access key, secret key or bucket).' >&2
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cat > "$work/audit.sh" <<'INNER'
set -uo pipefail
cd /work
B="s3://$BUCKET/docker/registry/v2"
PREFIX='docker/registry/v2/repositories/'

# S3 connection resets are common from some hosts, so every call retries.
ls_retry() {
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
: > live.txt
while IFS=$'\t' read -r repo tag; do
  d="$(cp_retry "$B/repositories/$repo/_manifests/tags/$tag/current/link")"
  d="${d#sha256:}"
  if [[ -z "$d" ]]; then
    echo "$repo:$tag -> tag link unreadable" >> dangling.txt
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
    echo "$repo:$tag -> could not verify (S3 errors), treating as a problem (sha256:${d:0:12})" >> dangling.txt
  else
    echo "$d" >> live.txt
  fi
done < tags.tsv

echo "Tags checked: $(wc -l < tags.tsv | tr -d ' ')   dangling: $(wc -l < dangling.txt | tr -d ' ')"
if [[ -s dangling.txt ]]; then
  echo 'Dangling tags:'
  sed 's/^/  /' dangling.txt
fi

missing=0
if [[ "$VERIFY_REFS" == 1 ]]; then
  # Walk down from every live tag's manifest. An index lists child manifests (followed); an image
  # manifest lists its config and layers (checked for existence, never opened: a config holds
  # diff_ids, which are not blobs in the registry).
  sort -u live.txt > todo.txt
  : > seen.txt
  : > refs.txt
  while [[ -s todo.txt ]]; do
    : > next.txt
    while read -r d; do
      grep -qxF "$d" seen.txt && continue
      echo "$d" >> seen.txt
      cp_retry "$B/blobs/sha256/${d:0:2}/$d/data" > one.json || continue
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
fi

[[ ! -s dangling.txt && "$missing" -eq 0 ]]
INNER

if docker run --rm \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION -e BUCKET -e VERIFY_REFS \
  -v "$work:/work" --entrypoint bash amazon/aws-cli /work/audit.sh; then
  printf '\n%s\n' 'Audit finished: no problems found.'
else
  printf '\n%s\n' 'Audit finished: problems found (or the audit could not complete). See above.' >&2
  exit 1
fi
