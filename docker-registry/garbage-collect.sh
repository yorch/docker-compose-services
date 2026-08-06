#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

usage() {
  printf 'Usage: %s [--dry-run] [--delete] [--delete-untagged]\n' "$0"
  printf '\n'
  printf '  --dry-run          Report unreferenced blobs without deleting them (default)\n'
  printf '  --delete           Delete unreferenced blobs from S3\n'
  printf '  --delete-untagged  Also delete manifests not referenced by a tag\n'
}

mode="--dry-run"
delete_untagged=""

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      mode="--dry-run"
      ;;
    --delete)
      mode=""
      ;;
    --delete-untagged)
      delete_untagged="--delete-untagged"
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

if [[ -n "$delete_untagged" && "$mode" == "--dry-run" ]]; then
  printf '%s\n' 'Refusing --delete-untagged without --delete.' >&2
  exit 2
fi

if [[ "$mode" == "--dry-run" ]]; then
  printf '%s\n' 'Running garbage collection in DRY-RUN mode.'
else
  printf '%s\n' 'WARNING: unreferenced blobs will be deleted from S3.'
  read -r -p 'Type DELETE to continue: ' confirmation
  [[ "$confirmation" == "DELETE" ]] || {
    printf '%s\n' 'Cancelled.'
    exit 1
  }
fi

registry_was_running=0
if docker compose ps --status running --services | grep -qx registry; then
  registry_was_running=1
  docker compose stop registry
fi

restart_registry() {
  if [[ "$registry_was_running" -eq 1 ]]; then
    docker compose start registry
  fi
}
trap restart_registry EXIT

gc_args=(registry garbage-collect /etc/distribution/config.yml)
[[ -n "$mode" ]] && gc_args+=("$mode")
[[ -n "$delete_untagged" ]] && gc_args+=("$delete_untagged")

docker compose run --rm --no-deps registry "${gc_args[@]}"

printf '%s\n' 'Garbage collection completed.'
