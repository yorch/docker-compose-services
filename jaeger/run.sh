#!/bin/bash

CMD="docker compose -f docker-compose.yml -f docker-compose.hotrod.yml"

${CMD} pull

${CMD} up -d
