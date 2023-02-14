#!/bin/bash

CMD="docker compose -f docker-compose.yml -f docker-compose.example-app.yml"

${CMD} pull

${CMD} up -d
