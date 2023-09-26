#!/bin/bash
# Description:
#  Configure helper for GnuPG credential helper for git repos
#
# Privilege required: sudo root
# OS: Debian
# Kernel: Linux
#
# Files impacted:
#  read   - ./.git/config
#  create - none
#  modify - none
#  delete - none
#
# Package Prerequisites (binaries):
#   apt (apt)
#   coreutils (tee)
#   dpkg (dpkg)
#   git (git)
#

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
echo

echo "Done."
