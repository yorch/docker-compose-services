#!/bin/bash
set -Eeuo pipefail

CMD="docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.alloy.yml"

${CMD} pull

${CMD} up -d
