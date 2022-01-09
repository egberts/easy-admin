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
echo ""
MINI_REPO="${PWD}"
OPENSSH_SSH_BIN_FILESPEC="/usr/bin/ssh"

function check_redhat_crypto_policy()
{
  sestatus_bin="$(whereis sestatus | awk '{print $2;}')"
  if [ -n "$sestatus_bin" ] && [ -e "$sestatus_bin" ]; then
    if [ -f /etc/ssh/ssh_config.d/05-redhat.conf ]; then
      echo "Ummmmm, Redhat Crypto Policy in effect."
      echo "Check /etc/ssh/ssh_config.d/05-redhat.conf if this is what you want"
      echo "Otherwise, remove/rename that file and re-run $0"
      echo "Aborted."
      exit 3
    fi
  fi
}

source ./ssh-openssh-common.sh

case $ID in
  debian|devuan)
    ;;
  centos)
    check_redhat_crypto_policy
    ;;
  fedora)
    check_redhat_crypto_policy
    ;;
  redhat)
    check_redhat_crypto_policy
    ;;
esac

DEFAULT_ETC_CONF_DIRNAME="ssh"

source ssh-openssh-common.sh

FILE_SETTINGS_FILESPEC="$BUILDROOT/file-settings-openssh-client.sh"
rm -f "$FILE_SETTINGS_FILESPEC"

REPO_DIR="$PWD/$ssh_configd_dirname"


echo "Check the OpenSSH client for appropriate file permission settings"
echo ""

if [ -z "$ssh_bin_filespec" ]; then
  echo "SSH client binary is not found; aborted."
  exit 9
fi

# Check if 'ssh' client is useable at file permission level
ssh_bin_filespec="$(whereis ssh|awk '{print $2;}')"
ssh_bin_group="$(stat -c%G $ssh_bin_filespec)"
ssh_perm="$(stat -c%a $ssh_bin_filespec)"
if [ "$ssh_perm" -gt "750" ]; then
  echo "But the $ssh_bin_filespec has sufficient $ssh_perm file permission;"
  echo "so anyone can use 'ssh'"
  echo "INFO: Perhaps, you really want to restrict 'ssh' binary being limited"
  echo "to just the users having supplemental '$ssh_bin_group' group for "
  echo "      limiting these outbound ssh sessions?"
  echo "To add group-privilege for remote SSH access, run:"
  echo "  usermod -a -G $ssh_bin_group <your-user-name>"
  echo "  chmod o-rwx $ssh_bin_filespec"
else
  # Check if anyone has 'ssh' (client) group access on this host
  SSH_USERS_BY_GROUP="$(grep "$SSH_GROUP_NAME" /etc/group | awk -F: '{ print $4; }' | xargs -n1 )"
  if [ -z "$SSH_USERS_BY_GROUP" ]; then
    echo "There is no one in the '$SSH_GROUP_NAME' group; "
    echo "The $ssh_bin_filespec has restrictive $ssh_perm file permission;"
    echo "Only user with '$ssh_bin_group' supplemental group can use this 'ssh' client binary"
    echo "no remote access possible."
    echo "To add remote access, run:"
    echo "  usermod -a -G $ssh_bin_group <your-user-name>"
    exit 1
  fi
fi

# Even if we are root, we abide by BUILDROOT directive as to
# where the final configuration settings goes into.
ABSPATH="$(dirname "$BUILDROOT")"
if [ "$ABSPATH" != "." ] && [ "${ABSPATH:0:1}" != '/' ]; then
  echo "$BUILDROOT is an absolute path, we probably need root privilege"
  echo "We are backing up old SSH settings"
  # Only the first copy is saved as the backup
  if [ ! -f "${ssh_config_filespec}.backup" ]; then
    BACKUP_FILENAME=".backup-$(date +'%Y%M%d%H%M')"
    echo "Moving /etc/ssh/* to /etc/ssh/${BACKUP_FILENAME}/ ..."
    mv "$ssh_config_filespec" "${ssh_config_filespec}.backup"
    retsts=$?
    if [ $retsts -ne 0 ]; then
      echo "ERROR: Failed to create a backup of /etc/ssh/*"
      exit 3
    fi
  fi
else
  echo "Creating subdirectories to $BUILDROOT ..."
  mkdir -p "$BUILDROOT"

  echo "Creating file permission script in $FILE_SETTINGS_FILESPEC ..."
  echo "#!/bin/bash" > "$FILE_SETTINGS_FILESPEC"
# shellcheck disable=SC2094
  { \
  echo "# File: $(basename "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Path: ${PWD}/$(dirname "$FILE_SETTINGS_FILESPEC")"; \
  echo "# Title: File permission settings for SSH client"; \
  } >> "$FILE_SETTINGS_FILESPEC"
fi

mkdir -p "$BUILDROOT$ssh_configd_dirspec"



# Update the SSH server settings
#

TEST_SSH_CONFIG_FILESPEC="build/${ssh_config_filename}.build-test-only"
TEST_SSH_CONFIGD_DIRSPEC="build/${ssh_configd_dirname}"

DATE="$(date)"
echo "Creating $TEST_SSH_CONFIG_FILESPEC ..."
cat << TEST_SSH_EOF | tee "$TEST_SSH_CONFIG_FILESPEC" >/dev/null
include "${TEST_SSH_CONFIGD_DIRSPEC}/*.conf"
TEST_SSH_EOF

echo "Creating ${BUILDROOT}$ssh_config_filespec ..."
cat << SSH_EOF | tee "${BUILDROOT}${ssh_config_filespec}" >/dev/null
#
# File: $SSH_CONFIG_FILENAME
# Path: $openssh_config_dirspec
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

include "${ssh_configd_dirspec}/*.conf"
SSH_EOF
flex_chmod 640 "$ssh_config_filespec"
flex_chown "root:$SSH_GROUP_NAME" "$ssh_config_filespec"

if [ ! -d "$REPO_DIR" ]; then
  echo "Repo directory $REPO_DIR missing; aborted."
  exit 9
fi
flex_mkdir ${ssh_configd_dirspec}
cp ${REPO_DIR}/* "${BUILDROOT}${ssh_configd_dirspec}/"

flex_chmod 750 "$ssh_configd_dirspec"
flex_chown "root:$SSH_GROUP_NAME" "$ssh_configd_dirspec"

CONF_LIST="$(find "${REPO_DIR}" -maxdepth 1 -name "*.conf")"
for this_subconf_file in $CONF_LIST; do
  base_name="$(basename "$this_subconf_file")"
  cp "$this_subconf_file" "${BUILDROOT}${ssh_configd_dirspec}/"
  flex_chmod 640 "${ssh_configd_dirspec}/$base_name"
  flex_chown "root:$SSH_GROUP_NAME" "${ssh_configd_dirspec}/$base_name"
done


echo "Checking ${BUILDROOT}${ssh_config_filespec} for any syntax error ..."
$OPENSSH_SSH_BIN_FILESPEC -G \
    -F ${TEST_SSH_CONFIG_FILESPEC} \
    localhost \
    >/dev/null 2>&1
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "Error during ssh config syntax checking. Showing error output"
  echo "Cmd: ssh -G -v -F ${TEST_SSH_CONFIG_FILESPEC} localhost" 
  echo "Showing ssh_config output"
  $OPENSSH_SSH_BIN_FILESPEC -G -v \
      -F "${TEST_SSH_CONFIG_FILESPEC}" \
      localhost
  exit "$retsts"
fi
echo "Passes syntax checks."
echo ""

# Check if non-root user has 'ssh' supplementary group membership

FOUND=0
USERS_IN_SSH_GROUP="$(grep "$SSH_GROUP_NAME" /etc/group | awk -F: '{ print $4 }' | xargs -n1)"
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
  echo "No user in '$SSH_GROUP_NAME' group."
  echo "User ${USER} cannot access this SSH server here."
  echo "Must execute:"
  echo "  usermod -a -G ${SSH_GROUP_NAME} ${USER}"
  exit 1
else
  echo "Only these users can use '${SSH_GROUP_NAME}' tools: '$USERS_IN_SSH_GROUP'"
  echo ""
  echo "If you have non-root apps that also uses '$ssh_bin_filespec', then add that user"
  echo "to the '$SSH_GROUP_NAME' supplemental group; run:"
  echo "  usermod -a -G ${SSH_GROUP_NAME} <username>"
fi
echo ""

echo "Done."
