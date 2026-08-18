#!/bin/bash
set -Eeuo pipefail

# Pre-run setup for the Loki stack. Idempotent - safe to re-run at any time.
#
# Everything here is a no-op on a host that is already set up, and the whole
# script is optional on macOS: Docker Desktop's virtiofs layer remaps bind mount
# ownership, so the problem it fixes only exists on Linux.
#
# It deliberately does NOT create the external `traefik` network. That is
# ../traefik3/setup.sh's job, shared by every service in this repo.

DATA_DIR=data/loki
# The UID baked into grafana/loki. Confirm after an image bump with:
#   docker inspect grafana/loki:<tag> --format '{{.Config.User}}'
LOKI_UID=10001

# --- .env ----------------------------------------------------------------

if [ -f .env ]; then
  echo "==> .env already exists, leaving it alone."
else
  cp .env.sample .env
  echo "==> Created .env from .env.sample."
  echo "    The dev overlay runs on the defaults; fill it in for Traefik."
fi

# --- Data directory ------------------------------------------------------

mkdir -p "${DATA_DIR}"

# Test what Loki will actually be able to do rather than comparing UIDs. On
# macOS a container reports this mount as owned by root even though writes
# succeed, so an ownership comparison would "fix" a directory that was never
# broken, on every run.
if docker run --rm \
  --user "${LOKI_UID}" \
  --volume "$(pwd)/${DATA_DIR}:/data" \
  alpine sh -c 'touch /data/.probe && rm /data/.probe' >/dev/null 2>&1; then
  echo "==> ${DATA_DIR} is writable by UID ${LOKI_UID}, nothing to do."
else
  echo "==> ${DATA_DIR} is not writable by UID ${LOKI_UID}, fixing ownership."
  # Done from a root container rather than with sudo: a regular user cannot
  # give a file away to another UID, and the daemon is already root.
  docker run --rm \
    --volume "$(pwd)/${DATA_DIR}:/data" \
    alpine chown -R "${LOKI_UID}:${LOKI_UID}" /data
  echo "    Done. Loki would otherwise have crash-looped on start with"
  echo "    'mkdir /loki/rules: permission denied'."
fi

# ./data/alloy needs nothing: the Alloy image runs as root, so the directory
# Docker creates for it is already writable.

# --- Basic auth credentials ----------------------------------------------

echo
echo "Generate a basic auth credential for the Traefik overlay? Only needed"
echo "for docker-compose.for-traefik.yml, and only once."
read -rp "Generate now? [y/N] " answer

case "${answer}" in
  [yY] | [yY][eE][sS]) ;;
  *)
    echo "Skipped. Setup complete."
    exit 0
    ;;
esac

read -rp "Username [admin]: " username
username="${username:-admin}"

# -s hides the password as it is typed, keeping it out of the terminal and out
# of shell history.
echo -n "Password for ${username}: "
read -rs password
echo
echo -n "Repeat password: "
read -rs password_repeat
echo

if [ "${password}" != "${password_repeat}" ]; then
  echo "Passwords do not match. Nothing was generated." >&2
  exit 1
fi

# -n prints to stdout instead of writing a file, -i reads the password from
# stdin so it never appears in the container's argv, -B selects bcrypt.
credential="$(printf '%s\n' "${password}" | docker run \
  --rm \
  --interactive \
  --entrypoint htpasswd \
  httpd:2 -niB "${username}")"

# Everything after the first colon is the hash.
hash="${credential#*:}"

# Double every $. Compose interpolates the values inside .env, so a bcrypt hash
# stored verbatim is read as variable references: $2y$05$Nx7... reaches Traefik
# as $2y$05 with the digest gone, and basic auth then rejects the correct
# password. Whether it corrupts at all depends on the character after each $,
# so an unescaped hash works roughly one time in six - just often enough to
# look like it is fine until the next rotation.
escaped_hash="$(printf '%s' "${hash}" | sed 's/\$/$$/g')"

echo
echo "Paste these two lines into .env, replacing the existing entries:"
echo
printf 'USERNAME=%s\n' "${username}"
printf 'HASHED_PASSWORD=%s\n' "${escaped_hash}"
echo
echo "The doubled \$\$ are intentional - compose consumes one from each pair,"
echo "so Traefik receives the correct single-\$ hash. Verify with:"
echo "  docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml config | grep basicauth"
