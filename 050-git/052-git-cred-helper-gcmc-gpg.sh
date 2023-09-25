#!/bin/bash
# File: 052-github-gcmc-auth-gpg.sh
# Title: Github Core credential helper for persistent authentication via GPG
# Description:
#  Install a GPG agent
#

sudo apt install gpg-agent

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
# Creator: $(realpath $0)
# Date: $(date)
#
echo "export GPG_TTY=\$(tty)"
EOF

