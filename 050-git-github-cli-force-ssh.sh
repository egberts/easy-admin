#!/bin/bash
# File: 050-git-github-cli-force-ssh.sh
# Title: Configure local account for CLI-based auth access with GitHub

# gh config set -h git_protocol ssh  # broken
gh config set -h git_protocol ssh  -h github.com # broken
