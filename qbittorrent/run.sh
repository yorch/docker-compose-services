#!/bin/bash
set -Eeuo pipefail

CMD="docker compose -f docker-compose.yml -f docker-compose.ports.yml"

${CMD} pull

${CMD} up -d
