#!/bin/bash
set -Eeuo pipefail

docker compose exec dbbackups /backup.sh
