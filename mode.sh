#!/usr/bin/env bash
# Record which compose files a service runs with, so plain `docker compose ps|logs|up -d|down` work in
# its folder without a pile of -f flags.
#
# Compose reads COMPOSE_FILE from the service's .env. This script maintains that one line.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  printf 'Usage: %s <service> [mode...]     record the compose files to use\n' "$0"
  printf '       %s <service>               show what is recorded and what is available\n' "$0"
  printf '       %s <service> --clear       forget the recorded files\n' "$0"
  printf '\n'
  printf '  <service>  a folder of this repo (grafana), or the path of any folder with a docker-compose.yml\n'
  printf '  mode...    overlays added to docker-compose.yml, in this order:\n'
  printf '               dev           docker-compose.dev.yml\n'
  printf '               for-traefik   docker-compose.for-traefik.yml (also: traefik)\n'
  printf '               <name>        docker-compose.<name>.yml, e.g. maintenance, ports, hotrod.for-traefik\n'
  printf '\n'
  printf 'Examples:\n'
  printf '  ./mode.sh grafana for-traefik\n'
  printf '  ./mode.sh docker-registry for-traefik maintenance\n'
  printf '  ./mode.sh jaeger dev hotrod\n'
}

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

[[ $# -ge 1 ]] || { usage >&2; exit 2; }
case "$1" in
  -h|--help) usage; exit 0 ;;
esac

service="$1"
shift
if [[ -f "$service/docker-compose.yml" ]]; then
  dir="$(cd "$service" && pwd)"
elif [[ -f "$ROOT/$service/docker-compose.yml" ]]; then
  dir="$ROOT/$service"
else
  die "No docker-compose.yml in '$service' (neither as a path nor as a folder of this repo)."
fi
name="$(basename "$dir")"
env_file="$dir/.env"

overlays() { # the overlay names that exist in the folder
  local f
  for f in "$dir"/docker-compose.*.yml; do
    [[ -e "$f" ]] || continue
    f="${f##*/docker-compose.}"
    printf '%s\n' "${f%.yml}"
  done
}

recorded() { # the COMPOSE_FILE line in .env (empty when there is none)
  [[ -f "$env_file" ]] || return 0
  sed -n 's/^COMPOSE_FILE=//p' "$env_file" | tail -n 1
}

if [[ -n "${COMPOSE_FILE:-}" ]]; then
  printf 'Note: COMPOSE_FILE is also set in your shell (%s); it overrides the .env file.\n' "$COMPOSE_FILE" >&2
fi

# ---------------------------------------------------------------- show
if [[ $# -eq 0 ]]; then
  current="$(recorded)"
  printf '%s\n' "$name"
  printf '  recorded:  %s\n' "${current:-(nothing: plain docker compose uses docker-compose.yml only)}"
  available="$(overlays | tr '\n' ' ')"
  printf '  available: %s\n' "${available:-(no overlays)}"
  exit 0
fi

# ---------------------------------------------------------------- clear
if [[ "$1" == --clear ]]; then
  if [[ -f "$env_file" ]] && grep -q '^COMPOSE_FILE=' "$env_file"; then
    tmp="$(mktemp)"
    grep -v '^COMPOSE_FILE=' "$env_file" > "$tmp" || true
    cat "$tmp" > "$env_file"
    rm -f "$tmp"
    printf '%s: forgot the recorded compose files.\n' "$name"
  else
    printf '%s: nothing was recorded.\n' "$name"
  fi
  exit 0
fi

# ---------------------------------------------------------------- record
files="docker-compose.yml"
seen=" "
for mode in "$@"; do
  [[ "$mode" != -* ]] || die "Unknown option: $mode"
  [[ "$mode" != traefik ]] || mode="for-traefik"
  [[ "$seen" != *" $mode "* ]] || continue
  seen="$seen$mode "
  if [[ ! -f "$dir/docker-compose.$mode.yml" ]]; then
    available="$(overlays | tr '\n' ' ')"
    die "$name has no docker-compose.$mode.yml. Available: ${available:-(none)}"
  fi
  files="$files:docker-compose.$mode.yml"
done

if [[ ! -f "$env_file" ]]; then
  if [[ -f "$dir/.env.sample" ]]; then
    die "$name has no .env yet. Create it first: ./setup-env.sh $name"
  fi
  : > "$env_file"
fi

line="COMPOSE_FILE=$files"
if grep -q '^COMPOSE_FILE=' "$env_file"; then
  tmp="$(mktemp)"
  awk -v line="$line" '/^COMPOSE_FILE=/ { if (!done) { print line; done = 1 }; next } { print }' "$env_file" > "$tmp"
  cat "$tmp" > "$env_file"
  rm -f "$tmp"
else
  # keep a file that does not end with a newline intact
  if [[ -s "$env_file" && -n "$(tail -c 1 "$env_file")" ]]; then printf '\n' >> "$env_file"; fi
  printf '%s\n' "$line" >> "$env_file"
fi

printf '%s: %s\n' "$name" "$files"
printf 'Plain `docker compose ps`, `logs -f`, `up -d` and `down` in %s now use these files.\n' "$dir"
