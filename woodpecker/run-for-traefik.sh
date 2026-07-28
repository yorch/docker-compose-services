#!/bin/bash

CMD="docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml"

${CMD} pull

${CMD} up -d
