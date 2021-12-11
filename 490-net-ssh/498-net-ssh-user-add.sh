#!/bin/bash
# File: 498-net-ssh-user-add.sh
# Title: Add authorized users to 'ssh' group for using 'ssh' tools

source ./ssh-openssh-common

if [ $UID -ne 0 ]; then
  echo "WARNING: sudo password may appear."
fi

read -rp "Add the name of user to '$SSH_GROUP' group [$USER]?: "
if [ -z "$REPLY" ]; then
  SSH_USER="$USER"
else
  SSH_USER="$REPLY"
fi

# check if user already has that supplemental group ID
USER_HAS_GID="$(egrep "^${SSH_USER}:" /etc/group | wc -l)"
if [ "$USER_HAS_GID" -ge 1 ]; then
  echo "User $SSH_USER already has $SSH_GROUP GID"
  echo ""
  echo "Done."
  exit 0
fi

# Add user to SSH group: who can log into this host?
echo "Executing: sudo addgroup $SSH_USER $SSH_GROUP"
sudo usermod -a -G "$SSH_GROUP" "$SSH_USER"
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "Unable to add '$SSH_USER' user to '$SSH_GROUP' group: Error $RETSTS"
  exit $RETSTS
fi
echo "Done."
