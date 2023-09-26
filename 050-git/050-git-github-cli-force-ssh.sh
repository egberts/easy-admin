#!/bin/bash
# File: 050-git-github-cli-force-ssh.sh
# Title: Configure local account for CLI-based auth access with GitHub
#
# Privilege required: sudo root
# OS: Debian
# Kernel: Linux
#
# Files impacted:
#  read   - /usr/bin/gh
#  create - none
#  modify - none
#  delete - none
#
# Environment Variables:
#   none
#
# Prerequisites:
#   gh (gh)
#   git (git)
#

# gh config set -h git_protocol ssh  # broken
# gh config set -h git_protocol ssh  -h github.com # broken
