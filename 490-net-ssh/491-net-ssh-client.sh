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
openssh_ssh_bin_filespec="/usr/bin/ssh"

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

source ./maintainer-ssh-openssh.sh

case $ID in
  debian|devuan)
    ;;
  centos|fedora|redhat)
    check_redhat_crypto_policy
    ;;
esac

readonly FILE_SETTINGS_FILESPEC="$BUILDROOT/file-settings-openssh-client.sh"
rm -f "$FILE_SETTINGS_FILESPEC"

repo_dirspec="$MINI_REPO/$SSH_CONFIGD_DIRNAME"


echo "Check the OpenSSH client for appropriate file permission settings"
echo ""

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
  ssh_users_by_group="$(grep "$SSH_GROUP_NAME" /etc/group | awk -F: '{ print $4; }' | xargs -n1)"
  if [ -z "$ssh_users_by_group" ]; then
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
absolute_dirname="$(dirname "$BUILDROOT")"
if [ "$absolute_dirname" != "." ] && [ "${absolute_dirname:0:1}" != '/' ]; then
  echo "$BUILDROOT is an absolute path, we probably need root privilege"
  echo "We are backing up old SSH settings"
  # Only the first copy is saved as the backup
  if [ ! -f "${SSH_CONFIG_FILESPEC}.backup" ]; then
    backup_filename=".backup-$(date +'%Y%M%d%H%M')"
    echo "Moving /etc/ssh/* to /etc/ssh/${backup_filename}/ ..."
    mv "$SSH_CONFIG_FILESPEC" "${SSH_CONFIG_FILESPEC}.backup"
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

mkdir -p "$BUILDROOT$SSH_CONFIGD_DIRSPEC"



# Update the SSH server settings
#

test_ssh_config_filespec="build/${SSH_CONFIG_FILENAME}.build-test-only"
test_ssh_configd_dirspec="build/${SSH_CONFIGD_DIRNAME}"

DATE="$(date)"
echo "Creating $test_ssh_config_filespec ..."
cat << TEST_SSH_EOF | tee "$test_ssh_config_filespec" >/dev/null
include "${test_ssh_configd_dirspec}/*.conf"
TEST_SSH_EOF

echo "Creating ${BUILDROOT}$SSH_CONFIG_FILESPEC ..."
cat << SSH_EOF | tee "${BUILDROOT}${SSH_CONFIG_FILESPEC}" >/dev/null
#
# File: $SSH_CONFIG_FILENAME
# Path: $OPENSSH_CONFIG_DIRSPEC
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
flex_chmod 640 "$SSH_CONFIG_FILESPEC"
flex_chown "root:$SSH_GROUP_NAME" "$SSH_CONFIG_FILESPEC"

if [ ! -d "$repo_dirspec" ]; then
  echo "Repo directory $repo_dirspec missing; aborted."
  exit 9
fi
flex_ckdir ${SSH_CONFIGD_DIRSPEC}
cp ${repo_dirspec}/* "${BUILDROOT}${SSH_CONFIGD_DIRSPEC}/"

flex_chmod 750 "$SSH_CONFIGD_DIRSPEC"
flex_chown "root:$SSH_GROUP_NAME" "$SSH_CONFIGD_DIRSPEC"

config_list="$(find "${repo_dirspec}" -maxdepth 1 -name "*.conf")"
for this_subconf_file in $config_list; do
  base_name="$(basename "$this_subconf_file")"
  cp "$this_subconf_file" "${BUILDROOT}${SSH_CONFIGD_DIRSPEC}/"
  flex_chmod 640 "${SSH_CONFIGD_DIRSPEC}/$base_name"
  flex_chown "root:$SSH_GROUP_NAME" "${SSH_CONFIGD_DIRSPEC}/$base_name"
done


echo "Checking ${BUILDROOT}${SSH_CONFIG_FILESPEC} for any syntax error ..."
$openssh_ssh_bin_filespec -G \
    -F ${test_ssh_config_filespec} \
    localhost \
    >/dev/null 2>&1
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "Error during ssh config syntax checking. Showing error output"
  echo "Cmd: ssh -G -v -F ${test_ssh_config_filespec} localhost"
  echo "Showing ssh_config output"
  $openssh_ssh_bin_filespec -G -v \
      -F "${test_ssh_config_filespec}" \
      localhost
  exit "$retsts"
fi
echo "Passes syntax checks."
echo ""

# Check if non-root user has 'ssh' supplementary group membership

found_a_user_with_access=0
users_in_ssh_group="$(grep "$SSH_GROUP_NAME" /etc/group | awk -F: '{ print $4 }' | xargs -n1)"
for THIS_USERS in $users_in_ssh_group; do
  for this_user in $(echo "$THIS_USERS" | sed 's/,/ /g' | xargs -n1); do
    if [ "${this_user}" == "${USER}" ]; then
      echo "User ${USER} has access to this hosts SSH server"
      found_a_user_with_access=1
    fi
  done
done

if [ $found_a_user_with_access -eq 0 ]; then
  echo "No one will be able to SSH outward of this box:"
  echo "No user in '$SSH_GROUP_NAME' group."
  echo "User ${USER} cannot access this SSH server here."
  echo "Must execute:"
  echo "  usermod -a -G ${SSH_GROUP_NAME} ${USER}"
  exit 1
else
  echo "Only these users can use '${SSH_GROUP_NAME}' tools: '$users_in_ssh_group'"
  echo ""
  echo "If you have non-root apps that also uses '$ssh_bin_filespec', then add that user"
  echo "to the '$SSH_GROUP_NAME' supplemental group; run:"
  echo "  usermod -a -G ${SSH_GROUP_NAME} <username>"
fi
echo ""

echo "Done."
