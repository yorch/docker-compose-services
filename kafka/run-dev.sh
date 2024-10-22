#!/bin/bash

CMD="docker compose -f docker-compose.yml -f docker-compose.dev.yml"

${CMD} pull

${CMD} up -d
