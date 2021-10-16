#!/bin/bash
#
# File: 490-net-ssh.sh
# Title: Setup and harden SSH server
#

MINI_REPO=${PWD}

# We are forcing no-root login permitted here
# so let us check to ensure that SOMEONE can
# log back in as non-root and become root

# Check if root takes a password locally on this host
WARNING_NO_ROOT_LOGIN=0

# Check for '!' substring in root entry of /etc/shadow file.
ROOT_LOGIN_PWD="$(sudo grep root /etc/shadow | awk -F: '{ print $2; }')"
if [[ "$ROOT_LOGIN_PWD" == *'!'* ]]; then
  WARNING_NO_ROOT_LOGIN=1
fi

# Check for '*' substring in root entry of /etc/shadow file.
if [[ "$ROOT_LOGIN_PWD" == *'*'* ]]; then
  WARNING_NO_ROOT_LOGIN=1
fi
echo "This host has no direct root login (only sudo)"

# Check if anyone has 'sudo' group access on this host
SUDO_USERS_BY_GROUP="$(grep sudo /etc/group | awk -F: '{ print $4; }')"
if [ -z "$SUDO_USERS_BY_GROUP" ]; then
  echo "There is no user account in the 'sudo' group; "

  # Well, no direct root and no sudo-able user account, this is rather bad.
  if [ $WARNING_NO_ROOT_LOGIN -ne 0 ]; then
    echo "no root access possible from non-root"
    echo "Run:"
    echo "  usermod -g sudo <your-user-name>"
    exit 1
  fi
fi

# Check if anyone has 'ssh' group access on this host
SSH_USERS_BY_GROUP="$(grep ssh /etc/group | awk -F: '{ print $4; }')"
if [ -z "$SSH_USERS_BY_GROUP" ]; then
  echo "There is no one in the 'ssh' group; "
  echo "no remote access possible."
  echo "To add remote access, run:"
  echo "  usermod -g ssh <your-user-name>"
  exit 1
fi


sudo apt install openssh-server

echo "We are blowing away the old SSH settings"

# Only the first copy is saved as the backup
if [ ! -f /etc/ssh/sshd_config.backup ]; then
  mv /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
fi

# Update the SSH server settings
#

DATE="$(date)"
cat << SSHD_EOF | sudo tee /etc/ssh/sshd_config
#
# File: sshd_config
# Path: /etc/ssh
# Title: SSH server configuration file
#
# Edition: sshd(8) v8.4p1 compiled-default
#          OpenSSL 1.1.1k  25 Mar 2021
#          \$ /usr/sbin/sshd -f /dev/null -T
# Creator: ${0}
# Date: ${DATE}
#
# Sort Order: Program Execution
#
# Description: OpenSSH server daemon configuration file
#
# The possible keywords and their meanings are as
# follows (note that keywords are case-insensitive and
# arguments are case-sensitive):

# Item Template:
# Channel type: all, kex (pre-channel), auth (pre-channel),
#               exec, shell, subsystem, pty-req, x11-req,
#               auth-agent-req, env
# CLI option: -d
# Process context: monitor (client), server_loop2, main (server)
# SSH service: ssh-userauth (SSH2_MSG_USERAUTH_REQUEST)
# XXXXXX defaults to XXXXXX.

# state actions
# 0. SSH version exchange
# 1. SSH2_MSG_KEXINIT
#      SSH2_MSG_KEX_ECDH_INIT
#      SSH2_MSG_NEWKEYS
#      SSH2_MSG_EXT_INFO
# 2. SSH2_MSG_CHANNEL_OPEN
# 3. SSH2_MSG_CHANNEL_REQUEST
# 3. SSH2_MSG_GLOBAL_REQUEST  (request_pty)
# x. SSH2_MSG_CHANNEL_DATA
# x. SSH2_MSG_CHANNEL_EXTENDED_DATA
#
# Abstraction Layers
# * Transport
#   ** SSHFP DNS record
# * User Authentication
# * Channel/Connection Layer

include "/etc/ssh/sshd_config.d/*.conf"
SSHD_EOF

sudo mkdir /etc/ssh/sshd_config.d
sudo cp "$MINI_REPO"/sshd_config.d/* /etc/ssh/sshd_config.d/


sudo chown root:ssh /etc/ssh/sshd_config
sudo chmod 640 /etc/ssh/sshd_config

sudo chown root:ssh /etc/ssh/sshd_config.d
sudo chmod 750 /etc/ssh/sshd_config.d

sudo chown root:ssh /etc/ssh/sshd_config.d/*
sudo chmod 640 /etc/ssh/sshd_config.d/*


sudo sshd -T -t
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "Error during ssh config syntax checking."
  exit 3
fi

# Check if non-root user has 'ssh' supplementary group membership

FOUND=0
USERS_IN_SSH_GROUP="$(grep ssh /etc/group | awk -F: '{ print $4 }')"
for THIS_USER in $USERS_IN_SSH_GROUP; do
  if [ "${THIS_USER}" == "${USER}" ]; then
    echo "User ${USER} has access to this hosts SSH server"
    FOUND=1
  fi
done

if [ $FOUND -eq 0 ]; then
  echo "User ${USER} cannot access this SSH server here."
  echo "Must execute:"
  echo "  usermod -g ssh ${USER}"
  exit 1
fi

sudo systemctl restart ssh.service

