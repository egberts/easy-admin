#!/bin/bash
# File: 498-net-ssh-user-add.sh
# Title: Add authorized users to 'ssh' group for using 'ssh' tools

read -rp "Add user to 'ssh' group [$USER]?: "

SSH_USER="$REPLY"

# Add user to SSH group: who can log into this host?
echo "Executing: sudo addgroup $SSH_USER ssh"
sudo addgroup "$SSH_USER" ssh
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "Unable to add '$SSH_USER' user to 'ssh' group: Error $RETSTS"
  exit $RETSTS
fi
echo "Done."
