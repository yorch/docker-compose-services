#!/bin/bash
set -Eeuo pipefail

CMD="docker compose -f docker-compose.yml"

${CMD} pull

${CMD} up -d
