#!/bin/bash
# File: 490-net-ssh-server.sh
# Title: Setup and harden SSH server
#
# Env Vars (and its default setting):
#   SSHD_CONF="$BUILDROOT/etc/ssh/sshd_config"
#   ALGORITHM_USED="ed25519"  # or "ecdsa"
#   BUILDROOT="build"
#   CHROOT_DIR=""
#   PREFIX="/usr"
#   EXEC_PREFIX="/usr"
#   LOCALSTATEDIR="/"  (Debian, /var for others)
#   SYSCONFDIR="/etc"
#   LIBDIR="$PREFIX/lib"
#
# System files:
#   Created: none
#   Modified: none

MINI_REPO="${PWD}"
DEFAULT_ETC_CONF_DIRNAME="ssh"

source ssh-openssh-common.sh
FILE_SETTINGS_FILESPEC="$BUILDROOT/file-settings-openssh-server.sh"
rm -f "${FILE_SETTINGS_FILESPEC}"

# Check if root takes a password locally on this host
WARNING_NO_ROOT_LOGIN=0

if [ "$USER" == "root" ]; then
  # We are forcing no-root login permitted here
  # so let us check to ensure that SOMEONE can
  # log back in as non-root and become root

  # Check for '!' substring in root entry of /etc/shadow file.
  ROOT_LOGIN_PWD="$(grep root /etc/shadow | awk -F: '{ print $2; }')"
  if [[ "$ROOT_LOGIN_PWD" == *'!'* ]]; then
    WARNING_NO_ROOT_LOGIN=1
  fi

  # Check for '*' substring in root entry of /etc/shadow file.
  if [[ "$ROOT_LOGIN_PWD" == *'*'* ]]; then
    WARNING_NO_ROOT_LOGIN=1
  fi
  echo "This host has no direct root login (only sudo)"
else
  echo "Non-root: Unable to check if direct root login is possible."
fi
echo ""

# Check if anyone has 'sudo' group access on this host
SUDO_USERS_BY_GROUP="$(grep sudo /etc/group | awk -F: '{ print $4; }')"
if [ -z "$SUDO_USERS_BY_GROUP" ]; then
  echo "There is no user account involving with the 'sudo' group; "
  echo "... You may want to add 'ssh' supplemental group to various users."

  # Well, no direct root and no sudo-able user account, this is rather bad.
  if [ $WARNING_NO_ROOT_LOGIN -ne 0 ]; then
    echo "no root access possible from non-root"
    echo ""
    echo "You probably need to run:"
    echo "  usermod -a -G sudo <your-user-name>"
    echo ""
    echo "And add a line to '/etc/sudoers':"
    echo "  %sudo   ALL=(ALL:ALL) ALL"
    echo ""
    exit 1
  fi
fi

# Check if anyone has 'ssh' group access on this host
SSH_USERS_BY_GROUP="$(grep $SSH_GROUP /etc/group | awk -F: '{ print $4; }')"
if [ -z "$SSH_USERS_BY_GROUP" ]; then
  echo "There is no one in the 'ssh' group; "
  echo "no remote access possible."
  echo "To add remote access, run:"
  echo "  usermod -a -G $SSH_GROUP <your-user-name>"
  exit 1
fi

SSHD_CONFIGD_DIRNAME="sshd_config.d"
SSHD_CONFIGD_DIRSPEC="$sysconfdir/$SSHD_CONFIGD_DIRNAME"
flex_mkdir "$SSHD_CONFIGD_DIRSPEC"

SSHD_CONFIG_FILENAME="sshd_config"
SSHD_CONFIG_FILESPEC="$sysconfdir/$SSHD_CONFIG_FILENAME"

# Only the first copy is saved as the backup
if [ ! -f "${SSHD_CONFIG_FILESPEC}.backup" ]; then
  mv "$SSHD_CONFIG_FILESPEC" "${SSHD_CONFIG_FILESPEC}.backup"
fi
flex_chown root:ssh "$SSHD_CONFIG_FILESPEC"
flex_chmod 640 "$SSHD_CONFIG_FILESPEC"


# Update the SSH server settings
#

cat << SSHD_EOF | tee "$BUILDROOT$SSHD_CONFIG_FILESPEC" >/dev/null 2>&1
#
# File: $SSHD_CONFIG_FILENAME
# Path: $sysconfdir
# Title: SSH server configuration file
#
# Edition: sshd(8) v8.4p1 compiled-default
#          OpenSSL 1.1.1k  25 Mar 2021
#          \$ /usr/sbin/sshd -f /dev/null -T
# Creator: $(basename "$0")
# Date: $(date)
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

include "${SSHD_CONFIGD_DIRSPEC}/*.conf"
SSHD_EOF

if [ ! -d "$SSHD_CONFIGD_DIRSPEC" ]; then
  flex_mkdir "$SSHD_CONFIGD_DIRSPEC"
fi
flex_chown root:ssh "$SSHD_CONFIGD_DIRSPEC"
flex_chmod 750 "$SSHD_CONFIGD_DIRSPEC"
cp "$MINI_REPO"/${SSHD_CONFIGD_DIRNAME}/* "$BUILDROOT$SSHD_CONFIGD_DIRSPEC"/

CONF_LIST="$(find ${SSHD_CONFIGD_DIRSPEC} -maxdepth 1 -name "*.conf")"
for this_subconf_file in $CONF_LIST; do
  flex_chown root:ssh "$this_subconf_file"
  flex_chmod 640 "$this_subconf_file"
done

# Fake generate throwaway host key for syntax-checking effort
TEMP_THROWAWAY_KEY="/tmp/fake-ssh-keys-$USER.key"
ssh-keygen -t ed25519 -f "${TEMP_THROWAWAY_KEY}" -q -N ""

# Check syntax of sshd_config/sshd_config.d/*.conf, et. al.
/usr/sbin/sshd -T -t \
    -f ${SSHD_CONFIG_FILESPEC} \
    -h ${TEMP_THROWAWAY_KEY} \
    >/dev/null 2>&1
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Error during ssh config syntax checking."
  echo "Showing sshd_config output"
  /usr/sbin/sshd -T -t -f ${BUILDROOT}${SSHD_CONFIG_FILESPEC} -h ${TEMP_THROWAWAY_KEY}
  rm "$TEMP_THROWAWAY_KEY"
  rm "${TEMP_THROWAWAY_KEY}.pub"
  exit "$retsts"
fi
echo "${BUILDROOT}$SSHD_CONFIG_FILESPEC passes syntax-checker."
echo ""
rm "$TEMP_THROWAWAY_KEY"
rm "${TEMP_THROWAWAY_KEY}.pub"

# Check if non-root user has 'ssh' supplementary group membership

FOUND=0
<<<<<<< Updated upstream
USERS_IN_SSH_GROUP="$(grep $SSH_GROUP /etc/group | awk -F: '{ print $4 }')"
for THIS_USERS in $USERS_IN_SSH_GROUP; do
  for this_user in $(echo "$THIS_USERS" | sed 's/,/ /g' | xargs -n1); do
    if [ "${this_user}" == "${USER}" ]; then
      echo "User ${USER} has access to this hosts SSH server"
      FOUND=1
    fi
  done
||||||| constructed merge base
USERS_IN_SSH_GROUP="$(grep ssh /etc/group | awk -F: '{ print $4 }')"
for THIS_USER in $USERS_IN_SSH_GROUP; do
  if [ "${THIS_USER}" == "${USER}" ]; then
    echo "User ${USER} has access to this hosts SSH server"
    FOUND=1
  fi
=======
USERS_IN_SSH_GROUP="$(grep ssh /etc/group | awk -F: '{ print $4 }')"
for THIS_USER in $USERS_IN_SSH_GROUP; do
  if [ "${THIS_USER}" == "${USER}" ]; then
    echo "User '${USER}' has access to this hosts SSH server"
    FOUND=1
  fi
>>>>>>> Stashed changes
done

if [ $FOUND -eq 0 ]; then
  echo "User ${USER} cannot access this SSH server here."
  echo "Must execute:"
  echo "  usermod -a -G $SSH_GROUP ${USER}"
  exit 1
fi
echo ""
echo "Done."
>>>>>>> Stashed changes
