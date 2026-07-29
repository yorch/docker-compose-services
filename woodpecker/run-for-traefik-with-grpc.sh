#!/bin/bash
set -Eeuo pipefail

CMD="docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml -f docker-compose.grpc.yml"

${CMD} pull

${CMD} up -d
