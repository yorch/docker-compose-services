#!/bin/bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Remember the compose files, so plain `docker compose ps|logs|down` work in this folder afterwards
../mode.sh . for-traefik hotrod hotrod.for-traefik

CMD="docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml -f docker-compose.hotrod.yml -f docker-compose.hotrod.for-traefik.yml"

${CMD} pull

${CMD} up -d
