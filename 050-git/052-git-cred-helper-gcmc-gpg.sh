#!/bin/bash
# File: 052-git-cred-helper-gcmc-gpg.sh
# Title: Github Core credential helper for persistent authentication via GPG
# Description:
#  Install a GPG agent
#
# Privilege required: sudo root
# OS: Debian
# Kernel: Linux
#
# Files impacted:
#  read   - /var/lib/dpkg
#           /etc/profile.d/gpg-agent
#  create - /etc/profile.d/gpg-agent
#  modify - none
#  delete - none
#
# Package Prerequisites (binaries):
#   apt (apt)
#   coreutils (tee)
#   dpkg (dpkg)
#

sudo apt install gpg-agent

PROGNAME="$0"
CREATOR_TXT="$(realpath "${PROGNAME}")"
DATE_TXT="$(date)"

cat << EOF | tee /etc/profile.d/gpg-agent >/dev/null
#
# File: gpg-agent
# Path: /etc/profile.d
# Title: headless/GUI-free PIN entry for GPG Agent
# Description:
#  Github Core (not Github CLI) recommends a secured storage for
#  their own authentication using GPG/PGP.
# Reference:
#  https://github.com/microsoft/Git-Credential-Manager-Core/linuxcredstores.md
# Creator: ${CREATOR_TXT}
# Date: ${DATE_TXT}
#
echo "export GPG_TTY=\$(tty)"
EOF
echo

echo "Done."
