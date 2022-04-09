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
echo ""

source ./maintainer-ssh-openssh.sh

# We are forcing no-root login permitted here
# so let us check to ensure that SOMEONE can
# log back in as non-root and become root

# Check if root takes a password locally on this host
warning_no_root_login=0

# Check for '!' substring in root entry of /etc/shadow file.
if [ -r /etc/shadow ]; then
  root_login_pwd="$(grep root /etc/shadow | awk -F: '{ print $2; }')"
  if [[ "$root_login_pwd" == *'!'* ]]; then
    warning_no_root_login=1
  fi
else
  echo "Skipping the check for no-root-login condition..."
fi

# Check for '*' substring in root entry of /etc/shadow file.
if [[ "$root_login_pwd" == *'*'* ]]; then
  warning_no_root_login=1
  echo "This host has no direct root login for SSH client."
fi

# Check if anyone has 'sudo' group access on this host
sudo_users_by_group="$(grep "$WHEEL_NAME" /etc/group | awk -F: '{ print $4; }')"
if [ -z "$sudo_users_by_group" ]; then
  echo "There is no user account involving with the '$WHEEL_NAME' group; "
  echo "... You may want to add 'ssh' supplemental group to various users."

  # Well, no direct root and no sudo-able user account, this is rather bad.
  if [ $warning_no_root_login -ne 0 ]; then
    echo "no root access possible from non-root"
    echo "Run:"
    echo "  usermod -a -G $WHEEL_NAME <your-user-name>"
    exit 1
  fi
fi
echo ""

# Check if 'sftponly' group exist
found_sftpusers_group="$(grep "$SSH_SFTP_GROUP_NAME" /etc/group | awk -F: '{ print $1; }')"
if [ -z "$found_sftpusers_group" ]; then
  echo "There is no one in the '$SSH_SFTP_GROUP_NAME' group; "
  echo "ALL remote file copy possible by ALL users."
  echo ""
  echo "To restrict sftp, run:"
  echo "  sudo groupadd --system $SSH_SFTP_GROUP_NAME"
  echo "  sudo useradd -a -G $SSH_SFTP_GROUP_NAME <username>"
  echo ""
  echo "Aborted."
  exit 1
fi
echo ""

sftp_server_binspec="${libdir}/${MAINT_SSH_DIR_NAME}/sftp-server"

# Even if we are root, we abide by BUILDROOT directive as to
# where the final configuration settings goes into.
absolute_dirname="$(dirname "$BUILDROOT")"
if [ "$absolute_dirname" != "." ] && [ "${absolute_dirname:0:1}" != '/' ]; then
  echo "$BUILDROOT is an absolute path, we probably need root privilege"
else
  echo "Creating subdirectories to $BUILDROOT ..."
  mkdir -p "$BUILDROOT"

  readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/filemod-sftp-users.sh"

  echo "Creating file permission script in $FILE_SETTINGS_FILESPEC ..."
  echo "#!/bin/bash" > "$FILE_SETTINGS_FILESPEC"
# shellcheck disable=SC2094
  { \
  echo "# File: $(basename "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Path: ${PWD}/$(dirname "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Title: File permission settings for SSH client"; \
  } >> "$FILE_SETTINGS_FILESPEC"
  mkdir -p "$BUILDROOT"
fi

# Create the build script file before checking if anyone is using it.
flex_chown root:${SSH_SFTP_GROUP_NAME} "$sftp_server_binspec"
flex_chmod 0750 "$sftp_server_binspec"

# Check if anyone has 'ssh' group access on this host
ssh_users_by_group="$(grep "$SSH_SFTP_GROUP_NAME" /etc/group | awk -F: '{ print $4; }')"
if [ -z "$ssh_users_by_group" ]; then
  echo "There is no one in the '$SSH_SFTP_GROUP_NAME' group; "
  echo "no remote file copy possible."
  echo ""
  echo "To add remote file copy by a user, run:"
  echo "  sudo usermod -a -G $SSH_SFTP_GROUP_NAME <your-user-name>"
  echo ""
  echo "Aborted."
  exit 1
fi
echo ""


found_user_in_supplemental_group=0
users_in_sftp_group="$(grep "^${SSH_SFTP_GROUP_NAME}:" /etc/group | awk -F: '{ print $4 }')"
for this_user_in_sftp_sgid in $users_in_sftp_group; do
  for this_user in $(echo "$this_user_in_sftp_sgid" | sed 's/,/ /g' | xargs -n1); do
    if [ "${this_user}" == "${USER}" ]; then
      echo "User ${USER} has access to this hosts SSH server"
      found_user_in_supplemental_group=1
    fi
  done
done

if [ $found_user_in_supplemental_group -eq 0 ]; then
  echo "No one will be able to \`scp\` to this box:"
  echo "No user in '$SSH_SFTP_GROUP_NAME' group."
  echo "User ${USER} cannot access this SFTP server here."
  echo "Must execute:"
  echo "  usermod -g ${SSH_SFTP_GROUP_NAME} ${USER}"
  exit 1
else
  echo "Only these users can use '${SSH_SFTP_GROUP_NAME}' tools: '$users_in_sftp_group'"
  echo
  echo "If you have non-root apps that also uses '${SSH_SFTP_GROUP_NAME}', then add that user"
  echo "to the '$SSH_SFTP_GROUP_NAME' supplemental group; run:"
  echo "  usermod -g ${SSH_SFTP_GROUP_NAME} <app-username>"
fi
echo

echo "Done."

