#!/bin/bash
set -Eeuo pipefail

# Creates or updates a user in ./data/auth/htpasswd, which config.json points
# Zot at. Zot supports bcrypt hashes only, hence -B - a file written with any
# other algorithm loads without complaint and then rejects every login.
#
# Two usernames are meaningful to the shipped config.json:
#   admin    - the only account allowed to push and delete (adminPolicy)
#   metrics  - the only account allowed to scrape /metrics
# Any other name gets pull-only access.

file_path=data/auth/htpasswd

if [ $# -ne 1 ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

username="${1}"

mkdir -p "$(dirname "${file_path}")"
touch "${file_path}"

if grep -q "^${username}:" "${file_path}"; then
  echo "User '${username}' already exists in '${file_path}', its password will be replaced."
fi

echo -n "Enter password for ${username}: "
# -s hides the password as it is typed.
read -rs password
echo

# -i reads the password from stdin, keeping it out of the container's argv.
printf '%s\n' "${password}" | docker run \
  --rm \
  --interactive \
  --entrypoint htpasswd \
  --volume "$(pwd)/${file_path}:/${file_path}" \
  httpd:2 -B -i "/${file_path}" "${username}"

echo "User '${username}' has been written to '${file_path}'."
echo "Zot picks the change up on its own - no restart needed."
