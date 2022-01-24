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

echo "Setting up OpenSSH daemon configuration file(s)"
echo 

source ./maintainer-ssh-openssh.sh

if [ "$BUILD_ABSOLUTE" -eq 0 ]; then
  FILE_SETTINGS_FILESPEC="${BUILD_DIRNAME}/file-settings-openssh-server.sh"
  rm -f "${FILE_SETTINGS_FILESPEC}"
fi

# Check if root takes a password locally on this host
WARNING_NO_ROOT_LOGIN=0

if [ "$USER" == "root" ]; then
  # We are forcing no-root login permitted here
  # so let us check to ensure that SOMEONE can
  # log back in as non-root and become root

  # Check for '!' substring in root entry of /etc/shadow file.
  ROOT_LOGIN_PWD="$(grep "^root:" /etc/shadow | awk -F: '{ print $2; }')"
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
echo 

# Check if anyone has 'sudo' group access on this host
SUDO_USERS_BY_GROUP="$(grep "^$WHEEL_GROUP:" /etc/group | awk -F: '{ print $4; }')"
if [ -z "$SUDO_USERS_BY_GROUP" ]; then
  echo "There is no user account involving with the '$WHEEL_GROUP' group; "
  echo "... Add a 'ssh' supplemental group to qualified user(s)."

  # Well, no direct root and no sudo-able user account, this is rather bad.
  if [ $WARNING_NO_ROOT_LOGIN -ne 0 ]; then
    echo "no root access possible from non-root"
    echo 
    echo "You probably need to run:"
    echo "  usermod -a -G $WHEEL_GROUP <your-user-name>"
    echo 
    echo "And add a line to '/etc/sudoers':"
    echo
    echo "  %$WHEEL_GROUP   ALL=(ALL:ALL) ALL"
    echo 
    exit 1
  fi
fi

# Check if 'sshd' group exist
SSHD_GROUP_FOUND="$(grep -c "^${SSHD_GROUP_NAME}:" /etc/group)"
if [ "$SSHD_GROUP_FOUND" -eq 0 ]; then
  echo "There is no '$SSHD_GROUP_NAME' group; "
  echo "Other process may view memory of SSH daemon process"
  echo "To add daemon access by UNIX group, run:"
  echo "  groupadd --system $SSHD_GROUP_NAME"
  echo 
  echo "Aborted."
  exit 1
fi

# Check if 'ssh' group exist
SSH_GROUP_FOUND="$(grep -c "^${SSH_GROUP_NAME}:" /etc/group)"
if [ "$SSH_GROUP_FOUND" -eq 0 ]; then
  echo "There is no '$SSH_GROUP_NAME' group; "
  echo "no remote access possible by this UNIX group name."
  echo "To add remote access by UNIX group, run:"
  echo "  groupadd --system $SSH_GROUP_NAME"
  echo 
  echo "Aborted."
  exit 1
fi

# Check if anyone has 'ssh' group access on this host
SSH_USERS_BY_GROUP="$(grep "^${SSH_GROUP_NAME}:" /etc/group | awk -F: '{ print $4; }')"
if [ -z "$SSH_USERS_BY_GROUP" ]; then
  echo "There is no one in the '$GROUP_NAME' group; "
  echo "Anyone can ssh outward."
  echo "Anyone can ssh inbound."
  echo "no remote access possible by UNIX group."
  echo "To add remote access by UNIX group, run:"
  echo "  usermod --append --groups $SSH_GROUP_NAME <your-user-name>"
  echo "or"
  echo "  usermod -a -G $SSH_GROUP_NAME <your-user-name>"
  echo 
  echo "Aborted."
  exit 1
fi

# Only the first copy is saved as the backup
if [ ! -f "${sshd_config_filespec}.backup" ]; then
  if [ "$BUILD_ABSOLUTE" -eq 1 ]; then
    mv "$sshd_config_filespec" "${sshd_config_filespec}.backup"
  fi
fi

# Update the SSH server settings
#

echo "Creating ${BUILDROOT}${CHROOT_DIR}$sshd_config_filespec ..."
cat << SSHD_EOF | tee "${BUILDROOT}$sshd_config_filespec" >/dev/null 2>&1
#
# File: $sshd_config_filename
# Path: $extended_sysconfdir
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

SSHD_EOF
flex_chmod 640 "$sshd_config_filespec"
flex_chown "root:$SSHD_GROUP_NAME" "$sshd_config_filespec"


if [ "$HAS_SSHD_CONFIG_D" -ne 0 ]; then

  cat << SSHD_EOF | tee -a "${BUILDROOT}$sshd_config_filespec" >/dev/null 2>&1
  include "${sshd_configd_dirspec}/*.conf"

SSHD_EOF

  flex_mkdir "$sshd_configd_dirspec"
  flex_chown "root:$SSHD_GROUP_NAME" "$sshd_configd_dirspec"
  flex_chmod 750 "$sshd_configd_dirspec"

  cp "${sshd_configd_dirname}"/*.conf "$BUILDROOT$sshd_configd_dirspec"/
  pushd .
  cd "${sshd_configd_dirname}"
  conf_list="$(find . -maxdepth 1 -name "*.conf")"
  popd
  for this_subconf_file in $conf_list; do
    flex_chown "root:$SSHD_GROUP_NAME" "${extended_sysconfdir}/${sshd_configd_dirname}/$this_subconf_file"
    flex_chmod 640 "${extended_sysconfdir}/${sshd_configd_dirname}/$this_subconf_file"
  done
else
  exit 123
#  otherwise, we do not have 'include' directive option available in openssh daemon config file

  # concatenate all the config files together into "/etc/ssh/sshd_config".
  conf_list="$(find "${MINI_REPO}/${sshd_configd_dirspec}" -maxdepth 1 -name "*.conf")"
  for this_subconf_file in $conf_list; do
    cat "$this_subconf_file" >> "$BUILDROOT$sshd_config_filespec"
  done
  flex_chown "root:$SSHD_GROUP_NAME" "$sshd_config_filespec"
  flex_chmod 640 "$sshd_config_filespec"
fi

# Fake generate throwaway host key for syntax-checking effort
TEMP_THROWAWAY_KEY="/tmp/fake-ssh-keys-$USER.key"
ssh-keygen -t ed25519 -f "${TEMP_THROWAWAY_KEY}" -q -N ""

# Check syntax of sshd_config/sshd_config.d/*.conf, et. al.
echo "Checking sshd_config syntax ..."
sudo /usr/sbin/sshd -T -t \
    -f "${BUILDROOT}${sshd_config_filespec}" \
    -h "${TEMP_THROWAWAY_KEY}" \
    >/dev/null 2>&1
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Error during ssh config syntax checking."
  echo "Showing sshd_config output"
  sudo /usr/sbin/sshd -T -t -f "${BUILDROOT}${sshd_config_filespec}" -h "${TEMP_THROWAWAY_KEY}"
  rm "$TEMP_THROWAWAY_KEY"
  rm "${TEMP_THROWAWAY_KEY}.pub"
  exit "$retsts"
fi
echo "${BUILDROOT}$sshd_config_filespec passes syntax-checker."
echo 
rm "$TEMP_THROWAWAY_KEY"
rm "${TEMP_THROWAWAY_KEY}.pub"

# Check if non-root user has 'ssh' supplementary group membership

FOUND=0
USERS_IN_SSH_GROUP="$(grep "$SSH_GROUP_NAME" /etc/group | awk -F: '{ print $4 }')"
for this_users in $USERS_IN_SSH_GROUP; do
  for this_user in $(echo "$this_users" | sed 's/,/ /g' | xargs -n1); do
    if [ "$this_user" == "$USER" ]; then
      echo "User ${USER} has access to this hosts SSH server"
      FOUND=1
    fi
  done
done

if [ $FOUND -eq 0 ]; then
  echo "User ${USER} cannot access this SSH server here."
  # check if this is root (and root passwd is disabled)
  if [ "$USER" != "root" ]; then
    echo "Must execute:"
    echo "  usermod -a -G $SSH_GROUP_NAME ${USER}"
    exit 1
  else
    echo "NOTICE: You probably want to re-run this script but as non-root."
  fi
fi

# check keys
ssh_keys_group_found="$(egrep "^${SSHKEY_GROUP_NAME}:" /etc/group)"
if [ -n "$ssh_keys_group_found" ]; then
  echo "SSH key group ID found: $SSHKEY_GROUP_NAME in /etc/group"
  file_list="ssh_host_rsa_key ssh_host_ecdsa_key ssh_host_ed25519_key"
  for this_file in $file_list; do
    key_file="${this_file}.key"
    flex_chmod 640 "$key_file"
    flex_chown "root:$SSHKEY_GROUP_NAME" "$this_file"
    flex_chmod 644 "$this_file"
    flex_chown "root:root" "$this_file"
  done
else
  echo "Warning: No $SSHKEY_GROUP_NAME group name found in /etc/group"
  echo "Probably leftover from Redhat/Fedora/CentOS distro"
  echo "To fix this, execute"
  echo "  groupadd -r $SSHKEY_GROUP_NAME"
  echo "then do"
  echo "  usermod -a -G $SSHKEY_GROUP_NAME ${USER}"
  echo "And add a one-shot 'sshd-keygen@.service' evoking "
  echo "  /usr/libexec/openssh/sshd-keygen"
  echo "or ignore this '${SSHKEY_GROUP_NAME}' group all together"
fi
echo

echo "Done."

