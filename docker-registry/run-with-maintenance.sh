#!/bin/bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# The maintenance container mounts this folder at the same absolute path (compose resolves paths on the host)
export MAINTENANCE_PROJECT_DIR="$PWD"

CMD="docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml -f docker-compose.maintenance.yml"

${CMD} pull

${CMD} up -d
