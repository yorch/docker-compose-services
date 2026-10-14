#!/bin/bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Remember the compose files, so plain `docker compose ps|logs|down` work in this folder afterwards
../mode.sh . ports

# Dedicated Dokku host: publishes 22/80/443
CMD="docker compose -f docker-compose.yml -f docker-compose.ports.yml"

${CMD} pull

${CMD} up -d
