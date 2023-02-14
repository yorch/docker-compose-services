#!/bin/bash

CMD="docker compose -f docker-compose.yml -f docker-compose.http-auth.yml"

$CMD pull

$CMD up -d
