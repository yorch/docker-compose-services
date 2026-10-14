#!/usr/bin/env bash
# docker compose for one service, with the compose files recorded for it (see mode.sh):
#
#   ./dc.sh docker-registry ps
#   ./dc.sh docker-registry logs -f registry
#
# Unlike dc-dev.sh this does not force the dev overlay; it runs what the service's .env records.
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

usage() {
  printf 'Usage: %s <service> <docker compose args...>\n' "$0"
  printf '       %s grafana logs -f\n' "$0"
  printf 'Record which compose files a service uses with: ./mode.sh <service> <mode...>\n'
}

service="${1:-}"
if [[ -z "$service" || "$service" == -* ]]; then
  usage >&2
  exit 2
fi
[[ -f "$service/docker-compose.yml" ]] || { printf 'No docker-compose.yml in %s\n' "$service" >&2; exit 1; }
shift

cd "$service"

# A service with overlays but no recorded file set would silently use its base file alone, which
# is not what anyone running `logs` or `down` means. Explicit -f flags are the caller's business.
explicit=0
for arg in "$@"; do
  case "$arg" in -f|--file|-f=*|--file=*) explicit=1 ;; esac
done
if [[ "$explicit" -eq 0 && -z "${COMPOSE_FILE:-}" ]] \
  && ! grep -q '^COMPOSE_FILE=' .env 2> /dev/null \
  && [[ "$(find . -maxdepth 1 -name 'docker-compose*.yml' | wc -l | tr -d ' ')" -gt 1 ]]; then
  printf 'No compose files are recorded for %s. Record them once, e.g.:\n' "$service" >&2
  printf '  ./mode.sh %s dev          (or: for-traefik, ...)\n' "$service" >&2
  printf '  ./mode.sh %s              (shows what is available)\n' "$service" >&2
  exit 1
fi

mkdir -p ./data
exec docker compose "$@"
