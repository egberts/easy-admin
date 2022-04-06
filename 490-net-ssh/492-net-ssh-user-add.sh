#!/bin/bash
# File: 498-net-ssh-user-add.sh
# Title: Add authorized users to 'ssh' group for using 'ssh' tools

echo "Adds outbound SSH privilege to a specified user"
echo

source ./maintainer-ssh-openssh.sh

echo "   using the '${SSH_GROUP_NAME}' supplementary group."
echo

default_user="$USER"

prompt_me="Add username to the '$SSH_GROUP_NAME' supplementary group?"
if [ -z "$default_user" ]; then
  prompt_me+=": "
else
  prompt_me+=" [$USER]: "
fi
read -rp "$prompt_me"
username_to_add_to_ssh=
if [ -z "$REPLY" ]; then
  username_to_add_to_ssh="$default_user"
else
  username_to_add_to_ssh="$REPLY"
fi
echo ""

if [ -z "$username_to_add_to_ssh" ]; then
  echo "Empty input; aborted."
  exit 3
fi

# check if user already has that supplemental group ID
user_has_that_sgid="$(grep -E '^ssh:' /etc/group | awk -F: '{print $4}' | grep -E -c '(,)?'$default_user'(,|$)')"
if [ "$user_has_that_sgid" -ge 1 ]; then
  echo "User $username_to_add_to_ssh already a member of $SSH_GROUP_NAME GID"
  echo
  default_user=
fi

if [ $UID -ne 0 ]; then
  SUDO_BIN="/usr/bin/sudo"
fi

echo "Preparing to execute:"
echo "   $SUDO_BIN usermod -a -G $SSH_GROUP_NAME $username_to_add_to_ssh"
if [ $UID -ne 0 ]; then
  read -rp "Execute above 'sudo' command? (N/y): " -ein
  REPLY="${REPLY:0:1}"
else
  REPLY='y'
fi
if [ "$REPLY" == 'y' ]; then

  # Add user to SSH group: who can log into this host?
  $SUDO_BIN usermod -a -G "$SSH_GROUP_NAME" "$username_to_add_to_ssh"
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "Unable to add '$username_to_add_to_ssh' user to '$SSH_GROUP_NAME' group: Error $retsts"
    exit $retsts
  fi
fi
echo

echo "Done."

