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

MINI_REPO="./sshd_config.d"

source ./ssh-openssh-common


# We are forcing no-root login permitted here
# so let us check to ensure that SOMEONE can
# log back in as non-root and become root

# Check if root takes a password locally on this host
WARNING_NO_ROOT_LOGIN=0

# Check for '!' substring in root entry of /etc/shadow file.
if [ -r /etc/shadow ]; then
  ROOT_LOGIN_PWD="$(grep root /etc/shadow | awk -F: '{ print $2; }')"
  if [[ "$ROOT_LOGIN_PWD" == *'!'* ]]; then
    WARNING_NO_ROOT_LOGIN=1
  fi
else
  echo "Skipping the check for no-root-login condition..."
fi

# Check for '*' substring in root entry of /etc/shadow file.
if [[ "$ROOT_LOGIN_PWD" == *'*'* ]]; then
  WARNING_NO_ROOT_LOGIN=1
fi
echo "This host has no direct root login (only sudo)"

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

# Even if we are root, we abide by BUILDROOT directive as to
# where the final configuration settings goes into.
ABSPATH="$(dirname "$BUILDROOT")"
if [ "$ABSPATH" != "." ] && [ "${ABSPATH:0:1}" != '/' ]; then
  echo "$BUILDROOT is an absolute path, we probably need root privilege"
  echo "We are backing up old SSH settings"
  # Only the first copy is saved as the backup
  if [ ! -f "${SSHD_CONF_FILESPEC}.backup" ]; then
    BACKUP_FILENAME=".backup-$(date +'%Y%M%d%H%M')"
    echo "Moving /etc/ssh/* to /etc/ssh/${BACKUP_FILENAME}/ ..."
    mv "$SSHD_CONF_FILESPEC" "${SSHD_CONF_FILESPEC}.backup"
    retsts=$?
    if [ $retsts -ne 0 ]; then
      echo "ERROR: Failed to create a backup of /etc/ssh/*"
      exit 3
    fi
  fi
else
  echo "Creating subdirectories to $BUILDROOT ..."
  mkdir -p "$BUILDROOT"

  FILE_SETTINGS_FILESPEC="${BUILDROOT}/filemod-openssh-sshd.sh"
  echo "Creating file permission script in $FILE_SETTINGS_FILESPEC ..."
  echo "#!/bin/bash" > "$FILE_SETTINGS_FILESPEC"
  echo "# File: $(basename "$FILE_SETTINGS_FILESPEC")" >> "$FILE_SETTINGS_FILESPEC"
  echo "# Path: ${PWD}/$(dirname "$FILE_SETTINGS_FILESPEC")" >> "$FILE_SETTINGS_FILESPEC"
  echo "# Title: File permission settings for SSH daemon"
fi

mkdir -p "$BUILDROOT$SSHD_CONFD_DIRSPEC"

flex_chown root:ssh "$SSHD_CONF_FILESPEC"
flex_chmod 640      "$SSHD_CONF_FILESPEC"


# Update the SSH server settings
#

create_script_header "$SSHD_CONF_FILESPEC" "OpenSSH daemon configuration file"

cat << SSHD_EOF | tee "$BUILDROOT$SSHD_CONF_FILESPEC" >/dev/null 2>&1
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

include "/etc/ssh/sshd_config.d/*.conf"
SSHD_EOF

# Create Debian-specific subdirectory for SSH-specific configuration settings
flex_mkdir "$SSHD_CONFD_DIRSPEC"
flex_chown root:ssh "$SSHD_CONFD_DIRSPEC"
flex_chmod 750 "$SSHD_CONFD_DIRSPEC"
cp "$MINI_REPO"/* "${BUILDROOT}$SSHD_CONFD_DIRSPEC"/

# shellcheck disable=SC2045
for this_file in $(ls -1 "${SSHD_CONFD_DIRSPEC}"/*); do
  flex_chown root:ssh "$this_file"
  flex_chmod 640 "$this_file"
done

# Touch an empty host key file
ALGORITHM_USED="${ALGORITHM_USED:-ed25519}"
SSH_KEY_FILESPEC="$ext_ssh_dirspec/ssh_host_${ALGORITHM_USED}_key"
flex_touch "$SSH_KEY_FILESPEC"
flex_chown root:ssh "$SSH_KEY_FILESPEC"
flex_chmod 600 "$SSH_KEY_FILESPEC"
touch "${BUILDROOT}${SSH_KEY_FILESPEC}"

if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
  chmod 600 "${BUILDROOT}${SSH_KEY_FILESPEC}"
fi

$OPENSSH_SSHD_BIN_FILESPEC -T -t \
    -h "${BUILDROOT}${ext_ssh_dirspec}/ssh_host_ed25519_key" \
    -f "${BUILDROOT}${SSHD_CONF_FILESPEC}" >/dev/null 2>&1
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Error during ssh config syntax checking."
  echo "Showing sshd_config output"
  $OPENSSH_SSHD_BIN_FILESPEC -T -t \
    -h "${BUILDROOT}${ext_ssh_dirspec}/ssh_host_ed25519_key" \
    -f "${BUILDROOT}${SSHD_CONF_FILESPEC}"
  exit "$retsts"
fi

# Check if non-root user has 'ssh' supplementary group membership

FOUND=0
USERS_IN_SSH_GROUP="$(grep $SSH_GROUP /etc/group | awk -F: '{ print $4 }')"
for THIS_USERS in $USERS_IN_SSH_GROUP; do
  for this_user in $(echo "$THIS_USERS" | sed 's/,/ /g' | xargs -n1); do
    if [ "${this_user}" == "${USER}" ]; then
      echo "User ${USER} has access to this hosts SSH server"
      FOUND=1
    fi
  done
done

if [ $FOUND -eq 0 ]; then
  echo "User ${USER} cannot access this SSH server here."
  echo "Must execute:"
  echo "  usermod -a -G $SSH_GROUP ${USER}"
  exit 1
fi

