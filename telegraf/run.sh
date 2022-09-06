#!/bin/bash

# https://www.influxdata.com/blog/docker-run-telegraf-as-non-root/
# https://github.com/influxdata/telegraf/issues/10050#issuecomment-968244937
export DOCKER_GROUP_ID=$(stat -c '%g' /var/run/docker.sock)

docker compose up -d
