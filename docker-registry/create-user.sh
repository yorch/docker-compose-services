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

# Search for the string at the beginning of any line
if grep -q "^${username}:" "$file_path"; then
  echo "The user already exists in '$file_path'"
  echo "Please choose another username or delete it from the file"
  exit 1
fi

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
  echo "File '${file_path}' already exists, appending to it."
else
  # If the file does not exist, create it
  touch "${file_path}"
  if [ $? -eq 0 ]; then
    echo "File '${file_path}' has been created."
  else
    echo "Failed to create file '${file_path}'."
  fi
fi

docker run \
  --entrypoint htpasswd \
  --rm \
  httpd:2 -Bbn ${username} ${password} >> ${file_path}

echo "User '${username}' has been created."
