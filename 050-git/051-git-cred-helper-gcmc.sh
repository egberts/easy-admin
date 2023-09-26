#!/bin/bash
# File: 051-git-cred-helper-gcmc.sh
# Title: Github Core credential helper for persistent authentication via Core
# Description:
#   Github Core can provide authentication for a 
#   headless/TTY-only environment such as a 
#   GUI-less/no-desktop server.
#
#   A better alternative is to use 052-github-auth-gpg.sh
#
# Privilege required: sudo root
# OS: Debian
# Kernel: Linux
#
# Files impacted:
#  read   - /var/tmp
#  create -
#  modify - none
#  delete - none
#
# Note:
#   This is a bizarre use of Microsoft DotNet for GUI-less hosts.
#   Made NOT an executable due to lack of security review
#
# Environment Variables:
#   BUILDROOT - set to '/' to actually install directly into your filesystem
#
# Prerequisites:
#   apt (apt)
#   dpkg (dpkg)
#   wget (wget)
#

cd /var/tmp || {
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "ERROR: No /var/tmp directory available; aborted"
    exit $RETSTS
  fi
}

# Download Github Core
wget https://github.com/microsoft/Git-Credential-Manager-Core/releases/download/v2.0.498/gcmcore-linux_amd64.2.0.498.54650.deb

# Install Github Credential Manager Core
sudo dpkg -i /tmp/gcmcore-linux_amd64.2.0.498.54650.deb
git-credential-manager-core configure

