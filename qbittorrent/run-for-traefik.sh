#!/bin/bash

CMD="docker compose -f docker-compose.base.yml -f docker-compose.ports.yml -f docker-compose.for-traefik.yml"

${CMD} pull

${CMD} up -d
