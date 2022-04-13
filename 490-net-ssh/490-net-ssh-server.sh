#!/bin/bash
# File: 490-net-ssh-server.sh
# Title: Setup and harden SSH server
#
# Env Vars (and its default setting):
#   SSHD_CONF="$BUILDROOT/etc/ssh/sshd_config"
#   ALGORITHM_USED="ed25519"  # but not "ecdsa" and certainly not "rsa"
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

function sshd_syntax_check()
{
  if [ "$SUDO_REQUIRED_SSHD" -ge 1 ]; then
    SUDO_BIN="/usr/bin/sudo"
    exit
  fi
    
  # Fake generate throwaway host key for syntax-checking effort
  temp_throwaway_key="fake-ssh-keys-$USER.key"
  ssh-keygen \
    -t ed25519 \
    -f "${BUILDROOT}${CHROOT_DIR}/${temp_throwaway_key}" \
    -q \
    -N ""

  # Check syntax of sshd_config/sshd_config.d/*.conf, et. al.
  echo "Checking sshd_config syntax ..."
  $SUDO_BIN /usr/sbin/sshd -T -t \
    -f "${BUILDROOT}${SSHD_CONFIG_FILESPEC}" \
    -h "${BUILDROOT}${CHROOT_DIR}/${temp_throwaway_key}" \
    >/dev/null 2>&1
    # -o ChrootDirectory="${BUILDROOT}${CHROOT_DIR}/" \
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "Error during ssh config syntax checking."
    echo "Showing sshd_config output"
    $SUDO_BIN /usr/sbin/sshd \
      -T \
      -t \
      -f "${BUILDROOT}${SSHD_CONFIG_FILESPEC}" \
      -h "${BUILDROOT}${CHROOT_DIR}/${temp_throwaway_key}"
      # -o ChrootDirectory="${BUILDROOT}${CHROOT_DIR}/" \
    rm "${BUILDROOT}${CHROOT_DIR}/$temp_throwaway_key"
    rm "${BUILDROOT}${CHROOT_DIR}/${temp_throwaway_key}.pub"
    exit "$retsts"
  fi
  echo "${BUILDROOT}$SSHD_CONFIG_FILESPEC passes syntax-checker."
  echo
  rm "${BUILDROOT}${CHROOT_DIR}/$temp_throwaway_key"
  rm "${BUILDROOT}${CHROOT_DIR}/${temp_throwaway_key}.pub"
}


if [ "$BUILD_ABSOLUTE" -eq 0 ]; then
  readonly FILE_SETTINGS_FILESPEC="${BUILD_DIRNAME}/file-settings-openssh-server.sh"
  rm -f "${FILE_SETTINGS_FILESPEC}"
fi

# Check if root takes a password locally on this host
warning_no_root_login=0

if [ "$USER" == "root" ]; then
  # We are forcing no-root login permitted here
  # so let us check to ensure that SOMEONE can
  # log back in as non-root and become root

  # Check for '!' substring in root entry of /etc/shadow file.
  root_login_pwd="$(grep "^root:" /etc/shadow | awk -F: '{ print $2; }')"
  if [[ "$root_login_pwd" == *'!'* ]]; then
    warning_no_root_login=1
  fi

  # Check for '*' substring in root entry of /etc/shadow file.
  if [[ "$root_login_pwd" == *'*'* ]]; then
    warning_no_root_login=1
  fi
  echo "This host has no direct root login (only sudo)"
else
  echo "Non-root: Unable to check if direct root login is possible."
fi
echo

# Check if anyone has 'sudo' group access on this host
sudo_users_by_group="$(grep "^$WHEEL_GROUP:" /etc/group | awk -F: '{ print $4; }')"
if [ -z "$sudo_users_by_group" ]; then
  echo "There is no user account involving with the '$WHEEL_GROUP' group; "
  echo "... Add a 'ssh' supplemental group to qualified user(s)."
  echo "... Do not do this step on a bastion SSH server for anyone."
  echo "... Such a bastion SSH server can only be root-login via a tty1"

  # Well, no direct root and no sudo-able user account, this is rather bad.
  if [ $warning_no_root_login -ne 0 ]; then
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
sshd_group_found="$(grep -c "^${SSHD_GROUP_NAME}:" /etc/group)"
if [ "$sshd_group_found" -eq 0 ]; then
  echo "There is no '$SSHD_GROUP_NAME' group; "
  echo "Other process may view memory of SSH daemon process"
  echo "To add daemon access by UNIX group, run:"
  echo "  groupadd --system $SSHD_GROUP_NAME"
  echo
  echo "Aborted."
  exit 1
fi

# Check if 'ssh' group exist
ssh_group_found="$(grep -c "^${SSH_GROUP_NAME}:" /etc/group)"
if [ "$ssh_group_found" -eq 0 ]; then
  echo "There is no '$SSH_GROUP_NAME' group; "
  echo "no remote access possible by this UNIX group name."
  echo "To add remote access by UNIX group, run:"
  echo "  groupadd --system $SSH_GROUP_NAME"
  echo
  echo "Aborted."
  exit 1
fi

# Check if anyone has 'ssh' group access on this host
ssh_users_by_group="$(grep "^${SSH_GROUP_NAME}:" /etc/group | awk -F: '{ print $4; }')"
if [ -z "$ssh_users_by_group" ]; then
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
if [ ! -f "${SSHD_CONFIG_FILESPEC}.backup" ]; then
  if [ "$BUILD_ABSOLUTE" -eq 1 ]; then
    mv "$SSHD_CONFIG_FILESPEC" "${SSHD_CONFIG_FILESPEC}.backup"
  fi
fi

# Update the SSH server settings
#

echo "Creating ${BUILDROOT}${CHROOT_DIR}$SSHD_CONFIG_FILESPEC ..."
cat << SSHD_EOF | tee "${BUILDROOT}$SSHD_CONFIG_FILESPEC" >/dev/null 2>&1
#
# File: $SSHD_CONFIG_FILENAME
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
flex_chmod 640 "$SSHD_CONFIG_FILESPEC"
flex_chown "root:$SSHD_GROUP_NAME" "$SSHD_CONFIG_FILESPEC"


if [ "$HAS_SSHD_CONFIG_D" -ne 0 ]; then

  cat << SSHD_EOF | tee -a "${BUILDROOT}$SSHD_CONFIG_FILESPEC" >/dev/null 2>&1
  include "${SSHD_CONFIGD_DIRSPEC}/*.conf"

SSHD_EOF

  flex_ckdir "$SSHD_CONFIGD_DIRSPEC"
  flex_chown "root:$SSHD_GROUP_NAME" "$SSHD_CONFIGD_DIRSPEC"
  flex_chmod 750 "$SSHD_CONFIGD_DIRSPEC"

  cp "${SSHD_CONFIGD_DIRNAME}"/*.conf "$BUILDROOT$SSHD_CONFIGD_DIRSPEC"/
  pushd .
  #shellcheck disable=SC2164
  cd "${SSHD_CONFIGD_DIRNAME}" ; retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "Error during 'cd ${SSHD_CONFIGD_DIRNAME}'; errno $retsts; aborted."
    exit $retsts
  fi

  conf_list="$(find . -maxdepth 1 -name "*.conf")"
  #shellcheck disable=SC2164
  popd ; retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "Error during popd; errno $retsts; aborted."
    exit $retsts
  fi
  for this_subconf_file in $conf_list; do
    flex_chown "root:$SSHD_GROUP_NAME" "${extended_sysconfdir}/${SSHD_CONFIGD_DIRNAME}/$this_subconf_file"
    flex_chmod 640 "${extended_sysconfdir}/${SSHD_CONFIGD_DIRNAME}/$this_subconf_file"
  done
else
  exit 123
#  otherwise, we do not have 'include' directive option available in openssh daemon config file

  # concatenate all the config files together into "/etc/ssh/sshd_config".
  conf_list="$(find "${MINI_REPO}/${SSHD_CONFIGD_DIRSPEC}" -maxdepth 1 -name "*.conf")"
  for this_subconf_file in $conf_list; do
    cat "$this_subconf_file" >> "$BUILDROOT$SSHD_CONFIG_FILESPEC"
  done
  flex_chown "root:$SSHD_GROUP_NAME" "$SSHD_CONFIG_FILESPEC"
  flex_chmod 640 "$SSHD_CONFIG_FILESPEC"
fi

if [ "$SYNTAX_CHECKABLE_SSHD" -ge 1 ]; then
  if [ "$SUDO_REQUIRED_SSHD" -ge 1 ]; then
    read -rp "Use sudo to perform passive syntax checking on $SSHD_CONFIG_FILESPEC? (y/N): " 
    if [ "${REPLY:0:1}" == 'y' ]; then
      sshd_syntax_check
    fi
  else
    sshd_syntax_check
  fi
else
  echo "No syntax checking available on $SSHD_CONFIG_FILESPEC without 'sudo'."
fi

# Check if non-root user has 'ssh' supplementary group membership

found_a_user_with_access=0
users_in_ssh_group="$(grep "$SSH_GROUP_NAME" /etc/group | awk -F: '{ print $4 }')"
for this_users in $users_in_ssh_group; do
  for this_user in $(echo "$this_users" | sed 's/,/ /g' | xargs -n1); do
    if [ "$this_user" == "$USER" ]; then
      echo "User ${USER} has access to this hosts SSH server"
      found_a_user_with_access=1
    fi
  done
done

if [ $found_a_user_with_access -eq 0 ]; then
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
ssh_keys_group_found="$(grep -E "^${SSHKEY_GROUP_NAME}:" /etc/group)"
if [ -n "$ssh_keys_group_found" ]; then
  echo "SSH key group ID found: $SSHKEY_GROUP_NAME in /etc/group"
  # file_list="ssh_host_rsa_key ssh_host_ecdsa_key ssh_host_ed25519_key"
  file_list="ssh_host_ed25519_key"
  for this_file in $file_list; do
    this_filespec="${extended_sysconfdir}/$this_file"
    if [ "$SSHKEY_GROUP_NAME" == 'root' ]; then
      flex_chmod 600 "$this_filespec"
    else
      flex_chmod 640 "$this_filespec"
    fi
    flex_chown "root:$SSHKEY_GROUP_NAME" "$this_filespec"
    pub_file="${extended_sysconfdir}/${this_file}.pub"
    flex_chmod 644 "$pub_file"
    flex_chown "root:root" "$pub_file"
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

