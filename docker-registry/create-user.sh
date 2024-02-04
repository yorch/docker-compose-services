#!/bin/bash

# Config

file_path=data/auth/htpasswd

# Check if a username has been passed as an argument
if [ $# -eq 0 ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

# The first argument is the username
username="$1"

# Prompt for the password
echo -n "Enter password for ${username}: "
# -s flag hides the password input
read -s password
echo

# Extract the directory path from the file path
dir_path=$(dirname "${file_path}")

# Ensure the directory exists
mkdir -p "${dir_path}"

# Check if the file exists
if [ -f "${file_path}" ]; then
  echo "File '${file_path}' already exists."
else
  # If the file does not exist, create it
  touch "${file_path}"
fi

docker run \
  --entrypoint htpasswd \
  httpd:2 -Bbn ${username} ${password} >> ${file_path}
