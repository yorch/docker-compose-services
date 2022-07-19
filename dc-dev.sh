#!/bin/bash

SERVICE="${1}"
ARGS="${@:2}"

echo "Setting Docker for service ${SERVICE} with arguments ${ARGS[@]}..."

cd "${SERVICE}"

mkdir -p ./data

docker compose \
    -f docker-compose.yml \
    -f docker-compose.dev.yml \
    ${ARGS[@]}
