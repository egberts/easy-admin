#!/bin/bash
# File: 051-github-gcmc.sh
# Title: Github Core credential helper for persistent authentication via Core
# Description:
#   Github Core can provide authentication for a 
#   headless/TTY-only environment such as a 
#   GUI-less/no-desktop server.
#
#   A better alternative is to use 052-github-auth-gpg.sh
#
# Note:
#   This is a bizarre use of Microsoft DotNet for GUI-less hosts.
#   Made NOT an executable due to lack of security review


cd /tmp

# Download Github Core
wget https://github.com/microsoft/Git-Credential-Manager-Core/releases/download/v2.0.498/gcmcore-linux_amd64.2.0.498.54650.deb

# Install Github Credential Manager Core
sudo dpkg -i /tmp/gcmcore-linux_amd64.2.0.498.54650.deb
git-credential-manager-core configure

