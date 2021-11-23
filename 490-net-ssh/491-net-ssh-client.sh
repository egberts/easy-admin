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
MINI_REPO="${PWD}"

source ./ssh-openssh-common

echo "Check the OpenSSH client for appropriate file permission settings"
echo ""

DEFAULT_ETC_CONF_DIRNAME="ssh"

source ssh-openssh-common.sh

SSH_CONFIG_FILENAME="ssh_config"
SSH_CONFIG_FILESPEC="${sysconfdir}/$SSH_CONFIG_FILENAME"

SSH_CONFIGD_DIRNAME="ssh_config.d"
SSH_CONFIGD_DIRSPEC="${sysconfdir}/$SSH_CONFIGD_DIRNAME"

REPO_DIR="$PWD/$SSH_CONFIGD_DIRNAME"

FILE_SETTINGS_FILESPEC="$BUILDROOT/file-settings-openssh-client.sh"
rm "$FILE_SETTINGS_FILESPEC"

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

# Check if anyone has 'ssh' group access on this host
SSH_USERS_BY_GROUP="$(grep "$SSH_GROUP" /etc/group | awk -F: '{ print $4; }')"
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

  FILE_SETTINGS_FILESPEC="${BUILDROOT}/filemod-openssh-ssh.sh"
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

DATE="$(date)"
echo "Creating ${BUILDROOT}$SSH_CONFIG_FILESPEC ..."
cat << SSH_EOF | tee "${BUILDROOT}${SSH_CONFIG_FILESPEC}" >/dev/null
#
# File: $SSH_CONFIG_FILENAME
# Path: $sysconfdir
# Title: SSH client configuration file
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

include "${SSH_CONFIGD_DIRSPEC}/*.conf"
SSH_EOF

if [ ! -d "$REPO_DIR" ]; then
  echo "Repo directory $REPO_DIR missing; aborted."
  exit 9
fi
flex_mkdir ${SSH_CONFIGD_DIRSPEC}
cp ${REPO_DIR}/* "${BUILDROOT}${SSH_CONFIGD_DIRSPEC}/"

flex_chmod 640 "$SSH_CONFIG_FILESPEC"
flex_chown root:ssh "$SSH_CONFIG_FILESPEC"

flex_chmod 750 "$SSH_CONFIGD_DIRSPEC"
flex_chown root:ssh "$SSH_CONFIGD_DIRSPEC"

CONF_LIST="$(find "${REPO_DIR}" -maxdepth 1 -name "*.conf")"
for this_subconf_file in $CONF_LIST; do
  base_name="$(basename "$this_subconf_file")"
  cp "$this_subconf_file" "${BUILDROOT}${SSH_CONFIGD_DIRSPEC}/"
  flex_chmod 640 "${SSH_CONFIGD_DIRSPEC}/$base_name"
  flex_chown root:ssh "${SSH_CONFIGD_DIRSPEC}/$base_name"
done


echo "Checking ${BUILDROOT}${SSH_CONFIG_FILESPEC} for any syntax error ..."
ssh -G localhost >/dev/null 2>&1
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "Error during ssh config syntax checking. Showing error output"
  echo "Cmd: ssh -G localhost -v"
  ssh -G localhost -v
  echo "Error during ssh config syntax checking."
  echo "Showing ssh_config output"
  $OPENSSH_SSH_BIN_FILESPEC -G -F "${BUILDROOT}${SSH_CONF_FILESPEC}" localhost
  exit "$retsts"
fi
echo "Passes syntax checks."
echo ""

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
echo ""

echo "Done."
