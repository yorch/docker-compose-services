#!/bin/bash
set -Eeuo pipefail

CMD="docker compose -f docker-compose.yml -f docker-compose.gluetun.yml"

${CMD} pull

${CMD} up -d
