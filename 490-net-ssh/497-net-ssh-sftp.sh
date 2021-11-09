#!/bin/bash
# File: 497-net-ssh-sftp.sh
# Title: Setup and harden SSH SFTP server
#
# Env Vars (and its default setting):
#   SSH_CONF="$BUILDROOT/etc/ssh/ssh_config"
#   BUILDROOT="build"
#   CHROOT_DIR=""
#   PREFIX="/usr"
#   EXEC_PREFIX="/usr"
#   LOCALSTATEDIR="/"  (Debian, /var for others)
#   SYSCONFDIR="/etc"
#   LIBDIR="$PREFIX/lib"
#

echo "Creating SSH SFTP server configuration settings..."

source ./ssh-openssh-common

SSH_SFTP_GROUP="sftpusers"

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
    echo "  usermod -a -G sudo <your-user-name>"
    exit 1
  fi
fi
echo ""

# Check if 'sftpusers' group exist
FOUND_SFTPUSERS_GROUP="$(grep "$SSH_SFTP_GROUP" /etc/group | awk -F: '{ print $4; }')"
if [ -z "$FOUND_SFTPUSERS_GROUP" ]; then
  echo "There is no one in the '$SSH_SFTP_GROUP' group; "
  echo "ALL remote file copy possible by ALL users."
  echo ""
  echo "To restrict sftp, run:"
  echo "  sudo groupadd --system $SSH_SFTP_GROUP"
  echo ""
  echo "Aborted."
  exit 1
fi
echo ""

# Check if anyone has 'ssh' group access on this host
SSH_USERS_BY_GROUP="$(grep "$SSH_SFTP_GROUP" /etc/group | awk -F: '{ print $4; }')"
if [ -z "$SSH_USERS_BY_GROUP" ]; then
  echo "There is no one in the '$SSH_SFTP_GROUP' group; "
  echo "no remote file copy possible."
  echo ""
  echo "To add remote file copy by a user, run:"
  echo "  sudo usermod -a -G $SSH_SFTP_GROUP <your-user-name>"
  echo ""
  echo "Aborted."
  exit 1
fi
echo ""
exit

flex_chown root:sftpusers /usr/lib/openssh/sftp-server
flex_chmod 0750 /usr/lib/ssh/opensftp-server

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

  FILE_SETTINGS_FILESPEC="${BUILDROOT}/filemod-sftp-users.sh"

  echo "Creating file permission script in $FILE_SETTINGS_FILESPEC ..."
  echo "#!/bin/bash" > "$FILE_SETTINGS_FILESPEC"
# shellcheck disable=SC2094
  { \
  echo "# File: $(basename "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Path: ${PWD}/$(dirname "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Title: File permission settings for SSH client"; \
  } >> "$FILE_SETTINGS_FILESPEC"
  mkdir -p "$BUILDROOT$SSH_CONFD_DIRSPEC"
fi

flex_chown root:${SSH_GROUP} "$SSH_CONF_FILESPEC"
flex_chmod 640      "$SSH_CONF_FILESPEC"


FOUND=0
USERS_IN_SFTP_GROUP="$(grep "$SSH_SFTP_GROUP" /etc/group | awk -F: '{ print $4 }')"
for THIS_USERS in $USERS_IN_SFTP_GROUP; do
  for this_user in $(echo "$THIS_USERS" | sed 's/,/ /g' | xargs -n1); do
    if [ "${this_user}" == "${USER}" ]; then
      echo "User ${USER} has access to this hosts SSH server"
      FOUND=1
    fi
  done
done

if [ $FOUND -eq 0 ]; then
  echo "No one will be able to \`scp\` to this box:"
  echo "No user in '$SSH_SFTP_GROUP' group."
  echo "User ${USER} cannot access this SFTP server here."
  echo "Must execute:"
  echo "  usermod -g ${SSH_SFTP_GROUP} ${USER}"
  exit 1
else
  echo "Only these users can use 'ssh' tools: '$USERS_IN_SFTP_GROUP'"
  echo ""
  echo "If you have non-root apps that also uses 'ssh', then add that user"
  echo "to the '$SSH_SFTP_GROUP' supplemental group; run:"
  echo "  usermod -g ${SSH_SFTP_GROUP} <app-username>"
fi

echo "Done."
