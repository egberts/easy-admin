#!/bin/bash
#
# File: 490-net-ssh.sh
# Title: Setup and harden SSH server
#

sudo apt install openssh-server

echo "We are blowing away the old SSH settings"

# Only the first copy is saved as the backup
if [ ! -f /etc/ssh/ssh_config.backup ]; then
  mv /etc/ssh/ssh_config /etc/ssh/ssh_config.backup
fi

# Update the SSH server settings
#

DATE="$(date)"
cat << SSH_EOF | sudo tee /etc/ssh/ssh_config >/dev/null
#
# File: ssh_config
#
# Title: SSH client configuration file
#
# Edition: ssh(8) v8.4p1 compiled-default
#          OpenSSL 1.1.1k  25 Mar 2021
#          \$ /usr/bin/ssh -G localhost
# Creator: ${0}
# Date: ${DATE}
#
# Sort Order: Program Execution
#
# Description: OpenSSH client daemon configuration file
#
# The possible keywords and their meanings are as
# follows (note that keywords are case-insensitive and
# arguments are case-sensitive):
#

include "/etc/ssh/ssh_config.d/*.conf"
SSH_EOF

sudo cp -v openssh/ssh_config.d/* /etc/ssh/ssh_config.d/


sudo chmod 640 /etc/ssh/ssh_config
sudo chown root:ssh /etc/ssh/ssh_config

sudo chmod 750 /etc/ssh/ssh_config.d
sudo chown root:ssh /etc/ssh/ssh_config.d

sudo chmod 640 /etc/ssh/ssh_config.d/*
sudo chown root:ssh /etc/ssh/ssh_config.d/*


# sudo ssh -G localhost
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "Error during ssh config syntax checking."
  exit 3
fi

# Check if non-root user has 'ssh' supplementary group membership
USERS_IN_SSH_GROUP="$(grep ssh /etc/group | awk -F: '{ print $4 }')"
if [ -z "$USERS_IN_SSH_GROUP" ]; then
  echo "No one will be able to SSH outward of this box:"
  echo "No user in 'ssh' group."
else
  echo "Only these users can use 'ssh' tools: '$USERS_IN_SSH_GROUP'"
  echo ""
  echo "If you have non-root apps that uses 'ssh', then run:"
  echo "  usermod -g ssh <app-username>"
fi


