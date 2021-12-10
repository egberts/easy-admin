#!/bin/bash
# File: 049-git-github-cli-install.sh
# Title: Install repository for Microsoft Github CLI tools

echo "Install repository to Microsoft Github CLI tool"

source /etc/os-release

function install_redhat_class_repo()
{
  sudo dnf config-manager \
        --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
  sudo dnf install gh
}

case $ID in
  'redhat')
    install_redhat_class_repo
    ;;
  'fedora')
    install_redhat_class_repo
    ;;
  'centos')
    install_redhat_class_repo
    ;;
  'debian')
    curl -fsSL \
        https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh
    ;;
  *)
    echo "Unknown OS type: '$ID'; aborted."
    exit 1
esac
echo ""

echo "Done."
