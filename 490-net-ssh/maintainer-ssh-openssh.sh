#
# File: maintainer-ssh-openssh.sh
# Title: Common settings for OpenSSH configuration
#
# Debian specific
# package_tarname= got broken apart by Debian into
# "openssh-server"/openssh-client
#
# Definable ENV variables
#   BUILDROOT
#   CHROOT_DIR
#   INSTANCE
#   SSHD_CONF
#   VAR_LIB_SSHD_DIRNAME - useful for multi-instances of 'sshd' daemons

CHROOT_DIR="${CHROOT_DIR:-}"
BUILD_DIRNAME="build"
BUILDROOT="${BUILDROOT:-${BUILD_DIRNAME}}"
BUILD_SSH="${BUILDROOT}/partial-ssh"
MINI_REPO="."

source ../easy-admin-installer.sh

DEFAULT_ETC_CONF_DIRNAME="ssh"

source ../distro-os.sh

# OpenSSH maintainer settings
extended_sysconfdir="${sysconfdir}/${DEFAULT_ETC_CONF_DIRNAME}"

SSHD_CONFIG_FILENAME="sshd_config"
SSHD_CONFIG_FILESPEC="${extended_sysconfdir}/$SSHD_CONFIG_FILENAME"
SSH_CONFIG_FILENAME="ssh_config"
SSH_CONFIG_FILESPEC="${extended_sysconfdir}/$SSH_CONFIG_FILENAME"

SSHD_CONFIGD_DIRNAME="sshd_config.d"
SSHD_CONFIGD_DIRSPEC="${extended_sysconfdir}/$SSHD_CONFIGD_DIRNAME"
SSH_CONFIGD_DIRNAME="ssh_config.d"
SSH_CONFIGD_DIRSPEC="${extended_sysconfdir}/$SSH_CONFIGD_DIRNAME"

# Build area
if [ "${BUILDROOT:0:1}" != '/' ]; then
  # relative build, create all subdirectories
  # absolute build, do not create build or certain rootfs subdirectories
  if [ ! -d "$BUILDROOT" ]; then
    mkdir -p "$BUILDROOT"   # the ONLY '-p' option for mkdir, anywhere
    # must account for all creations of subdir without using '-p' anywhere else
  fi
  if [ -n "$CHROOT_DIR" ]; then
    flex_ckdir "$CHROOT_DIR"
  fi
  flex_ckdir "${CHROOT_DIR}$sysconfdir"
  flex_ckdir "${CHROOT_DIR}$extended_sysconfdir"
  flex_ckdir "${CHROOT_DIR}$VAR_DIRSPEC"
  flex_ckdir "${CHROOT_DIR}$VAR_LIB_DIRSPEC"
  BUILD_ABSOLUTE=0
else
  BUILD_ABSOLUTE=1
fi

SSH_CONFIG_FILENAME="ssh_config"
SSHD_CONFIG_FILENAME="sshd_config"
OPENSSH_CONFIG_DIRSPEC="$extended_sysconfdir"
SSH_CONFIG_FILESPEC="${OPENSSH_CONFIG_DIRSPEC}/$SSH_CONFIG_FILENAME"
SSHD_CONFIG_FILESPEC="${OPENSSH_CONFIG_DIRSPEC}/$SSHD_CONFIG_FILENAME"

# ssh_confd_dirspec="$extended_sysconfdir/ssh_config.d"
# sshd_confd_dirspec="$extended_sysconfdir/sshd_config.d"

# FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-settings-ssh-common.sh"
if [ "$FILE_SETTING_PERFORM" == "true" ]; then
  if [ -n "$FILE_SETTINGS_FILESPEC" ]; then
    if [ -f "$FILE_SETTINGS_FILESPEC" ]; then
      rm -f "$FILE_SETTINGS_FILESPEC"
    fi
  fi
fi

[[ -n "$VERBOSE" ]] && echo "Detected $ID distro."

case $ID in
  debian|devuan)
    USER_NAME="ssh"  # to be replaced by SSH[D]_USER_NAME
    GROUP_NAME="ssh"  # to be replaced by SSH[D]_GROUP_NAME
    SSH_USER_NAME="ssh"  # future proofing
    SSH_GROUP_NAME="ssh"  # future proofing
    SSHD_USER_NAME="sshd"  # future proofing
    SSHD_GROUP_NAME="sshd"  # future proofing
    SSHKEY_USER_NAME="ssh_keys"  # future proofing
    SSHKEY_GROUP_NAME="ssh_keys"  # future proofing
    SSH_SFTP_USER_NAME="sftpusers"
    SSH_SFTP_GROUP_NAME="sftponly"
    WHEEL_GROUP="sudo"
    package_tarname="openssh"
    package_tarname="openssh"
    systemd_unitname="ssh"
    sysvinit_unitname="ssh"
    if [ "$VERSION_ID" -le 7 ]; then
      HAS_SSHD_CONFIG_D=0
      HAS_SSH_CONFIG_D=0
    else
      HAS_SSHD_CONFIG_D=1
      HAS_SSH_CONFIG_D=1
    fi
    ;;
  fedora)
    USER_NAME="sshd"
    GROUP_NAME="sshd"  # there is also 'ssh_keys' group
    SSH_USER_NAME="ssh"
    SSH_GROUP_NAME="ssh"
    SSHD_USER_NAME="sshd"
    SSHD_GROUP_NAME="sshd"
    SSHKEY_USER_NAME="ssh_keys"
    SSHKEY_GROUP_NAME="ssh_keys"
    SSH_SFTP_USER_NAME="sftpusers"
    SSH_SFTP_GROUP_NAME="sftponly"
    WHEEL_GROUP="wheel"
    clients_package_tarname="openssh-clients"
    server_package_tarname="openssh-server"
    package_tarname="openssh"
    systemd_unitname="sshd.service"
    sysvinit_unitname="sshd"
    HAS_SSH_CONFIG_D=0
    if [ "$VERSION_ID" -le 28 ]; then
      HAS_SSHD_CONFIG_D=0
    else
      HAS_SSHD_CONFIG_D=1
    fi
    echo "May have to execute 'semanage port -a -t ssh_port_t -p tcp <port>'"
    ;;
  redhat)
    USER_NAME="sshd"
    GROUP_NAME="sshd"  # there is also 'ssh_keys' group
    SSH_USER_NAME="ssh"
    SSH_GROUP_NAME="ssh"
    SSHD_USER_NAME="sshd"
    SSHD_GROUP_NAME="sshd"
    SSHKEY_USER_NAME="ssh_keys"
    SSHKEY_GROUP_NAME="ssh_keys"
    SSH_SFTP_USER_NAME="sftpusers"
    SSH_SFTP_GROUP_NAME="sftponly"
    WHEEL_GROUP="wheel"
    clients_package_tarname="openssh-clients"
    server_package_tarname="openssh-server"
    package_tarname="openssh"
    systemd_unitname="sshd.service"
    sysvinit_unitname="sshd"
    HAS_SSH_CONFIG_D=0
    if [ "$VERSION_ID" -le 9 ]; then
      HAS_SSHD_CONFIG_D=0
    else
      HAS_SSHD_CONFIG_D=1
    fi
    echo "May have to execute 'semanage port -a -t ssh_port_t -p tcp <port>'"
    ;;
  centos)
    USER_NAME="sshd"
    GROUP_NAME="sshd"  # there is also 'ssh_keys' group
    SSH_USER_NAME="ssh"
    SSH_GROUP_NAME="ssh"
    SSHD_USER_NAME="sshd"
    SSHD_GROUP_NAME="sshd"
    SSHKEY_USER_NAME="ssh_keys"
    SSHKEY_GROUP_NAME="ssh_keys"
    SSH_SFTP_USER_NAME="sftpusers"
    SSH_SFTP_GROUP_NAME="sftponly"
    WHEEL_GROUP="wheel"
    clients_package_tarname="openssh-clients"
    server_package_tarname="openssh-server"
    package_tarname="openssh"
    systemd_unitname="sshd.service"
    sysvinit_unitname="sshd"
    HAS_SSH_CONFIG_D=0
    if [ "$VERSION_ID" -le 8 ]; then
      HAS_SSHD_CONFIG_D=0
    else
      HAS_SSHD_CONFIG_D=1
    fi
    echo "May have to execute 'semanage port -a -t ssh_port_t -p tcp <port>'"
    ;;
  arch)
    USER_NAME="sshd"
    GROUP_NAME="sshd"
    SSH_USER_NAME="ssh"
    SSH_GROUP_NAME="ssh"
    SSHD_USER_NAME="sshd"
    SSHD_GROUP_NAME="sshd"
    SSHKEY_USER_NAME="ssh_keys"
    SSHKEY_GROUP_NAME="ssh_keys"
    SSH_SFTP_USER_NAME="sftpusers"
    SSH_SFTP_GROUP_NAME="sftponly"
    WHEEL_GROUP="wheel"
    package_tarname="openssh"
    systemd_unitname="sshd.service"
    sysvinit_unitname="sshd"
    HAS_SSH_CONFIG_D=1
    HAS_SSHD_CONFIG_D=1
    echo "May have to execute 'semanage port -a -t ssh_port_t -p tcp <port>'"
    ;;
esac

flex_ckdir "$sysconfdir"


if [ 0 -ne 0 ]; then
  # We will assume that /etc/ssh is not installed, so create them anyway
  flex_mkdir "$extended_sysconfdir"

  if [ "$HAS_SSHD_CONFIG_D" -ne 0 ]; then
    flex_mkdir "$SSHD_CONFIGD_DIRSPEC"
  fi

  if [ "$HAS_SSH_CONFIG_D" -ne 0 ]; then
    flex_mkdir "$SSH_CONFIGD_DIRSPEC"
  fi
fi  # [0 -ne 0] needs copying into other main SSH scripts

SSH_FOUND=0
EXECUTABLE_SSH=0
SYNTAX_CHECKABLE_SSH=0
SUDO_REQUIRED_SSH=0
SSH_BIN_FILESPEC="$( whereis ssh | awk '{print $2}')"
if [ -z "$SSH_BIN_FILESPEC" ]; then
  echo "Binary $SSH_BIN_FILESPEC not found in \$PATH"
  echo "No syntax checking will be done."
else
  SSH_FOUND=1
fi
if [ ! -f "$SSH_BIN_FILESPEC" ]; then
  echo "Binary $SSH_BIN_FILESPEC does not exist."
  echo "'sudo' may be required to do optional syntax-checking"
else
  SYNTAX_CHECKABLE_SSH=1
fi
SSH_BIN_GROUP="$(stat -c %G "$SSH_BIN_FILESPEC")"
if [ -x "$SSH_BIN_FILESPEC" ]; then
  EXECUTABLE_SSH=1
else
  SUDO_REQUIRED_SSH=1
fi

SSHD_FOUND=0
EXECUTABLE_SSHD=0
SYNTAX_CHECKABLE_SSHD=0
SUDO_REQUIRED_SSHD=0
SSHD_BIN_FILESPEC="$( whereis sshd | awk '{print $2}')"
if [ -z "$SSHD_BIN_FILESPEC" ]; then
  echo "Binary $SSHD_BIN_FILESPEC not found in \$PATH"
  echo "No syntax checking will be done."
else
  SSHD_FOUND=1
fi
if [ ! -f "$SSHD_BIN_FILESPEC" ]; then
  echo "Binary $SSHD_BIN_FILESPEC does not exist."
  echo "'sudo' may be required to do optional syntax-checking"
else
  SYNTAX_CHECKABLE_SSHD=1
fi
SSHD_BIN_GROUP="$(stat -c %G "$SSHD_BIN_FILESPEC")"
if [ -x "$SSHD_BIN_FILESPEC" ]; then
  EXECUTABLE_SSHD=1
else
  SUDO_REQUIRED_SSHD=1
fi

SSHD_HOME_DIRSPEC="$( egrep "^${SSHD_USER_NAME}:" /etc/passwd | awk -F: '{print $6 }')"


VAR_RUN_SSHD_DIRSPEC="${rundir}/sshd"
