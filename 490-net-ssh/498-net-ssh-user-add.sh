#!/bin/bash
# File: 498-net-ssh-user-add.sh
# Title: Add authorized users to 'ssh' group for using 'ssh' tools

source ./ssh-openssh-common

read -rp "Add user to '$SSH_GROUP' group [$USER]?: "

SSH_USER="$REPLY"

# Add user to SSH group: who can log into this host?
echo "Executing: sudo addgroup $SSH_USER $SSH_GROUP"
sudo addgroup "$SSH_USER" $SSH_GROUP
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "Unable to add '$SSH_USER' user to '$SSH_GROUP' group: Error $RETSTS"
  exit $RETSTS
fi
echo "Done."
