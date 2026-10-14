#!/bin/bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Remember the compose files, so plain `docker compose ps|logs|down` work in this folder afterwards
../mode.sh . ports dev

CMD="docker compose -f docker-compose.yml -f docker-compose.ports.yml -f docker-compose.dev.yml"

${CMD} pull

${CMD} up -d
