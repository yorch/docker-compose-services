#!/usr/bin/env bash
# Dump a service's PostgreSQL cluster before a major-version upgrade.
#
#   ./pg-dump.sh <service>          # from the repo root
#   ../pg-dump.sh .                 # from inside the service folder
#
# Useful after the compose file already points at the new major: the old stack can no
# longer start, so this mounts the old data directory in a matching postgres image and
# takes a pg_dumpall. It never moves or deletes data; the restore stays manual.
#
# Writes <service>/data/pg<major>-dump-<timestamp>.sql and prints the next commands.
# Refuses to run while the service's database container is up.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  printf 'Usage: %s <service>\n' "$0"
  printf '\n'
  printf '  <service>  a folder of this repo (nocodb), or any folder with a docker-compose.yml\n'
  printf '\n'
  printf 'Environment:\n'
  printf '  PG_SERVICE     override the detected postgres service name\n'
  printf '  PG_DUMP_IMAGE  override the postgres:<old-major> image used to read the cluster\n'
}

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

[[ $# -eq 1 ]] || { usage >&2; exit 2; }
case "$1" in
  -h | --help) usage; exit 0 ;;
esac

service="$1"
if [[ -f "$service/docker-compose.yml" ]]; then
  dir="$(cd "$service" && pwd)"
elif [[ -f "$ROOT/$service/docker-compose.yml" ]]; then
  dir="$ROOT/$service"
else
  die "No docker-compose.yml in '$service' (neither as a path nor as a folder of this repo)."
fi
name="$(basename "$dir")"
env_file="$dir/.env"

command -v jq > /dev/null || die 'jq is required.'
[[ -f "$env_file" ]] || die "No .env in $name. Create it with ../setup-env.sh $name first."
cd "$dir"

cfg="$(docker compose config --format json)"
svc="${PG_SERVICE:-$(jq -r '
  .services
  | to_entries[]
  | select((.value.image // "") | test("(^|/)postgres:|pgvector/pgvector:"))
  | .key
' <<< "$cfg" | head -n 1)}"
[[ -n "$svc" ]] || die "No PostgreSQL service found in $name/docker-compose.yml."

image="$(jq -r --arg s "$svc" '.services[$s].image // empty' <<< "$cfg")"
source="$(jq -r --arg s "$svc" '
  .services[$s].volumes[]?
  | select(.type == "bind")
  | select(.target | test("postgres|pgdata"))
  | .source
' <<< "$cfg" | head -n 1)"
[[ -n "$source" ]] || die "Service '$svc' has no PostgreSQL bind mount; nothing to dump."
[[ -d "$source" ]] || die "Data directory $source does not exist."

case "$image" in
  *timescale* | *timescaledb*) die "TimescaleDB uses a different PGDATA layout; this helper does not support it." ;;
esac

# Target major comes from the image tag: postgres:18-alpine, pgvector/pgvector:pg18, ...
tag="${image##*:}"
[[ "$tag" == "$image" ]] && tag="latest"
if [[ "$tag" =~ ^pg([0-9]+) ]]; then
  target="${BASH_REMATCH[1]}"
elif [[ "$tag" =~ ^([0-9]+) ]]; then
  target="${BASH_REMATCH[1]}"
else
  die "Cannot read a PostgreSQL major from image '$image'."
fi

# Current major from the old cluster. PostgreSQL 18 stores its cluster in <major>/docker,
# older images use the mounted directory itself.
if [[ -f "$source/PG_VERSION" && -f "$source/$target/docker/PG_VERSION" ]]; then
  current="$(tr -d '[:space:]' < "$source/PG_VERSION")"
  die "Found both a PostgreSQL $current cluster and a $target cluster in $source. Move the old directory aside first."
fi
if [[ -f "$source/PG_VERSION" ]]; then
  current="$(tr -d '[:space:]' < "$source/PG_VERSION")"
elif [[ -f "$source/$target/docker/PG_VERSION" ]]; then
  printf 'Data in %s already uses PostgreSQL %s; nothing to dump.\n' "$source" "$target"
  exit 0
elif [[ -z "$(ls -A "$source" 2> /dev/null || true)" ]]; then
  printf 'Data directory %s is empty; start the stack to initialize PostgreSQL %s.\n' "$source" "$target"
  exit 0
else
  die "Cannot find PG_VERSION in $source; is it a PostgreSQL data directory?"
fi

if [[ "$current" == "$target" ]]; then
  printf 'Data in %s already uses PostgreSQL %s; nothing to dump.\n' "$source" "$current"
  exit 0
fi
if ((current > target)); then
  die "Data is PostgreSQL $current but the compose file targets $target (downgrade is not supported)."
fi

if [[ -n "$(docker compose ps -q "$svc" 2> /dev/null || true)" ]]; then
  die "The '$svc' container is running. Stop the stack first: docker compose down"
fi

repo="${image%@*}"
repo="${repo%:*}"
case "$repo" in
  postgres | library/postgres | docker.io/library/postgres) dump_image="postgres:${current}-alpine" ;;
  pgvector/pgvector) dump_image="pgvector/pgvector:pg${current}" ;;
  *) dump_image="${repo}:${current}" ;;
esac
dump_image="${PG_DUMP_IMAGE:-$dump_image}"

mkdir -p data
timestamp="$(date +%Y%m%d-%H%M%S)"
dump="data/pg${current}-dump-${timestamp}.sql"
tmp="pgdump-${name}-$$"

cleanup() { docker rm -f "$tmp" > /dev/null 2>&1 || true; }
trap cleanup EXIT

printf 'Dumping PostgreSQL %s from %s with %s...\n' "$current" "$source" "$dump_image"
docker run -d --name "$tmp" --env-file "$env_file" \
  -v "$source:/var/lib/postgresql/data" "$dump_image" > /dev/null

for _ in $(seq 1 60); do
  docker exec "$tmp" pg_isready > /dev/null 2>&1 && break
  sleep 1
done
docker exec "$tmp" pg_isready > /dev/null 2>&1 \
  || die "The temporary $dump_image container did not become ready."

docker exec "$tmp" sh -c 'pg_dumpall -U "${POSTGRES_USER:-postgres}"' > "$dump"
if [[ ! -s "$dump" ]] || ! grep -q 'PostgreSQL database dump' "$dump"; then
  rm -f "$dump"
  die "Dump failed or is empty; nothing was changed."
fi

rel_source="${source#"$PWD"/}"
printf '\nWrote %s (%s bytes)\n' "$dump" "$(wc -c < "$dump" | tr -d ' ')"
printf 'The old data directory is untouched.\n\n'
printf 'Next steps:\n'
printf '  docker compose down\n'
printf '  mv %s %s.pg%s\n' "$rel_source" "$rel_source" "$current"
printf '  docker compose up -d --wait %s\n' "$svc"
printf "  docker compose exec -T %s sh -c 'psql -U \"\$POSTGRES_USER\" -d postgres' < %s\n" "$svc" "$dump"
printf '  docker compose up -d\n'
