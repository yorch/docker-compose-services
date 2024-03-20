#!/bin/bash

CMD="docker compose -f docker-compose.yml"

${CMD} pull

${CMD} up -d
