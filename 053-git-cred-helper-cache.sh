#!/bin/bash


CRED_NOW="$(git config credential.helper)"
if [ -z "${CRED_NOW}" ]; then
  echo "No git credential helper set."
else
  echo "Git credential helper set to '${CRED_NOW}'."
  exit 1
fi

# System-wide, set Git credential helper to cache of 1 hour (3600 seconds)
sudo git config --system credential.helper "cache --timeout 3600"

echo "Run 'git help credential-cache' for more details."
