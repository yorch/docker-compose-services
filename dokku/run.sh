#!/bin/bash
set -Eeuo pipefail

# Dedicated Dokku host: publishes 22/80/443
CMD="docker compose -f docker-compose.yml -f docker-compose.ports.yml"

${CMD} pull

${CMD} up -d
