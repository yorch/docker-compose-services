#!/bin/bash

CMD="docker compose -f docker-compose.yml -f docker-compose.gluetun.yml"

${CMD} pull

${CMD} up -d
