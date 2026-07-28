#!/bin/bash

CMD="docker compose -f docker-compose.yml -f docker-compose.ports.yml"

${CMD} pull

${CMD} up -d
