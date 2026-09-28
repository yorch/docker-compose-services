#!/bin/bash
# Create (or add a user to) the broker's password file before the first start.
# The file must exist before `docker compose up`: a bind mount of a missing file
# makes Docker create a directory there, and the broker then crash-loops.
#
# Usage: ./setup.sh <username>   (prompts for the password)
set -Eeuo pipefail
cd "$(dirname "$0")"

USERNAME="${1:?usage: ./setup.sh <username>}"
PASSWD_FILE=config/mosquitto/passwd

[ -d "$PASSWD_FILE" ] && { echo "$PASSWD_FILE is a directory (created by an earlier start); remove it first" >&2; exit 1; }
touch "$PASSWD_FILE"
chmod 600 "$PASSWD_FILE"

# Runs as root in a throwaway container, then hands the file to the broker's
# user with the permissions mosquitto 2.x expects.
docker compose run --rm --no-deps -e MQ_USER="$USERNAME" mqtt sh -c '
  mosquitto_passwd /mosquitto/config/passwd "$MQ_USER" &&
  chown mosquitto:mosquitto /mosquitto/config/passwd &&
  chmod 0700 /mosquitto/config/passwd'

echo "User '$USERNAME' saved to $PASSWD_FILE. Start the broker with: docker compose up -d"
