#!/bin/bash
# File: 490-net-ssh-client.sh
# Title: Setup and harden SSH server
#
# Env Vars (and its default setting):
#   SSH_CONF="$BUILDROOT/etc/ssh/ssh_config"
#   ALGORITHM_USED="ed25519"  # or "ecdsa"
#   BUILDROOT="build"
#   CHROOT_DIR=""
#   PREFIX="/usr"
#   EXEC_PREFIX="/usr"
#   LOCALSTATEDIR="/"  (Debian, /var for others)
#   SYSCONFDIR="/etc"
#   LIBDIR="$PREFIX/lib"
#

echo "Creating SSH client configuration files..."
MINI_REPO="./ssh_config.d"

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
  echo "This host has no direct root login for SSH client."
fi

# Check if anyone has 'sudo' group access on this host
SUDO_USERS_BY_GROUP="$(grep sudo /etc/group | awk -F: '{ print $4; }')"
if [ -z "$SUDO_USERS_BY_GROUP" ]; then
  echo "There is no user account involving with the 'sudo' group; "
  echo "... You may want to add 'ssh' supplemental group to various users."

  # Well, no direct root and no sudo-able user account, this is rather bad.
  if [ $WARNING_NO_ROOT_LOGIN -ne 0 ]; then
    echo "no root access possible from non-root"
    echo "Run:"
    echo "  usermod -g sudo <your-user-name>"
    exit 1
  fi
fi
echo ""

# Check if anyone has 'ssh' group access on this host
SSH_USERS_BY_GROUP="$(grep "$SSH_GROUP" /etc/group | awk -F: '{ print $4; }')"
if [ -z "$SSH_USERS_BY_GROUP" ]; then
  echo "There is no one in the 'ssh' group; "
  echo "no remote access possible."
  echo "To add remote access, run:"
  echo "  usermod -g $SSH_GROUP <your-user-name>"
  exit 1
fi

# Even if we are root, we abide by BUILDROOT directive as to
# where the final configuration settings goes into.
ABSPATH="$(dirname "$BUILDROOT")"
if [ "$ABSPATH" != "." ] && [ "${ABSPATH:0:1}" != '/' ]; then
  echo "$BUILDROOT is an absolute path, we probably need root privilege"
  echo "We are backing up old SSH settings"
  # Only the first copy is saved as the backup
  if [ ! -f "${SSH_CONF_FILESPEC}.backup" ]; then
    BACKUP_FILENAME=".backup-$(date +'%Y%M%d%H%M')"
    echo "Moving /etc/ssh/* to /etc/ssh/${BACKUP_FILENAME}/ ..."
    mv "$SSH_CONF_FILESPEC" "${SSH_CONF_FILESPEC}.backup"
    retsts=$?
    if [ $retsts -ne 0 ]; then
      echo "ERROR: Failed to create a backup of /etc/ssh/*"
      exit 3
    fi
  fi
else
  echo "Creating subdirectories to $BUILDROOT ..."
  mkdir -p "$BUILDROOT"

  FILE_SETTINGS_FILESPEC="${BUILDROOT}/filemods_openssh_ssh.sh"
  echo "Creating file permission script in $FILE_SETTINGS_FILESPEC ..."
  echo "#!/bin/bash" > "$FILE_SETTINGS_FILESPEC"
# shellcheck disable=SC2094
  { \
  echo "# File: $(basename "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Path: ${PWD}/$(dirname "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Title: File permission settings for SSH client"; \
  } >> "$FILE_SETTINGS_FILESPEC"
fi

mkdir -p "$BUILDROOT$SSH_CONFD_DIRSPEC"

flex_chown root:ssh "$SSH_CONF_FILESPEC"
flex_chmod 640      "$SSH_CONF_FILESPEC"


# Update the SSH server settings
#

create_script_header "$SSH_CONF_FILESPEC" "OpenSSH daemon configuration file"

cat << SSH_EOF | tee "$BUILDROOT$SSH_CONF_FILESPEC" >/dev/null 2>&1
#
# Edition: ssh(8) v8.4p1 compiled-default
#          OpenSSL 1.1.1k  25 Mar 2021
#          \$ /usr/sbin/ssh -f /dev/null -T
# Creator: $(basename "$0")
# Date: $(date)
#
# Sort Order: Program Execution
#
# Description: OpenSSH client daemon configuration file
#
# The possible keywords and their meanings are as
# follows (note that keywords are case-insensitive and
# arguments are case-sensitive):

include "/etc/ssh/ssh_config.d/*.conf"
SSH_EOF

# Create Debian-specific subdirectory for SSH-specific configuration settings
flex_mkdir "$SSH_CONFD_DIRSPEC"
flex_chown root:ssh "$SSH_CONFD_DIRSPEC"
flex_chmod 750 "$SSH_CONFD_DIRSPEC"
cp "$MINI_REPO"/* "${BUILDROOT}$SSH_CONFD_DIRSPEC"/

if [ ! -d "${BUILDROOT}${SSH_CONFD_DIRSPEC}" ]; then
  echo "Mmmmmm."
  exit 0
fi
CONFD_DIRLIST="$(ls -1 "${BUILDROOT}${SSH_CONFD_DIRSPEC}"/*)"
for this_file in $CONFD_DIRLIST; do
  this_confd="${SSH_CONFD_DIRSPEC}/$(basename "$this_file")"
  flex_chown root:ssh "$this_confd"
  flex_chmod 640 "$this_confd"
done
echo ""

$OPENSSH_SSH_BIN_FILESPEC -G -F "${BUILDROOT}${SSH_CONF_FILESPEC}" localhost >/dev/null 2>&1
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Error during ssh config syntax checking."
  echo "Showing ssh_config output"
  $OPENSSH_SSH_BIN_FILESPEC -G -F "${BUILDROOT}${SSH_CONF_FILESPEC}" localhost
  exit "$retsts"
fi

# Check if non-root user has 'ssh' supplementary group membership

FOUND=0
USERS_IN_SSH_GROUP="$(grep "$SSH_GROUP" /etc/group | awk -F: '{ print $4 }')"
for THIS_USERS in $USERS_IN_SSH_GROUP; do
  for this_user in $(echo "$THIS_USERS" | sed 's/,/ /g' | xargs -n1); do
    if [ "${this_user}" == "${USER}" ]; then
      echo "User ${USER} has access to this hosts SSH server"
      FOUND=1
    fi
  done
done

if [ $FOUND -eq 0 ]; then
  echo "No one will be able to SSH outward of this box:"
  echo "No user in '$SSH_GROUP' group."
  echo "User ${USER} cannot access this SSH server here."
  echo "Must execute:"
  echo "  usermod -g ${SSH_GROUP} ${USER}"
  exit 1
else
  echo "Only these users can use 'ssh' tools: '$USERS_IN_SSH_GROUP'"
  echo ""
  echo "If you have non-root apps that also uses 'ssh', then add that user"
  echo "to the '$SSH_GROUP' supplemental group; run:"
  echo "  usermod -g ${SSH_GROUP} <app-username>"
fi

echo "Done."
