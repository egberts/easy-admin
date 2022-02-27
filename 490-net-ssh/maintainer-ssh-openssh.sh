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
#   NAMED_CONF
#   VAR_LIB_NAMED_DIRNAME - useful for multi-instances of 'named' daemons

CHROOT_DIR="${CHROOT_DIR:-}"
BUILD_DIRNAME="build"
BUILDROOT="${BUILDROOT:-${BUILD_DIRNAME}/}"
BUILD_SSH="${BUILDROOT}/partial-ssh"
MINI_REPO="."

source ../easy-admin-installer.sh

DEFAULT_ETC_CONF_DIRNAME="ssh"

source ../distro-os.sh

# OpenSSH maintainer settings
extended_sysconfdir="${sysconfdir}/${DEFAULT_ETC_CONF_DIRNAME}"

sshd_config_filename="sshd_config"
sshd_config_filespec="${extended_sysconfdir}/$sshd_config_filename"
ssh_config_filename="ssh_config"
ssh_config_filespec="${extended_sysconfdir}/$ssh_config_filename"

sshd_configd_dirname="sshd_config.d"
sshd_configd_dirspec="${extended_sysconfdir}/$sshd_configd_dirname"
ssh_configd_dirname="ssh_config.d"
ssh_configd_dirspec="${extended_sysconfdir}/$ssh_configd_dirname"

# Build area

if [ "${BUILDROOT:0:1}" != '/' ]; then
  # relative build, create subdirectories
  # absolute build, do not create build directory
  if [ ! -d "$BUILDROOT" ]; then
    mkdir -p "$BUILDROOT"
  fi
  mkdir -p "${BUILDROOT}$sysconfdir"
  BUILD_ABSOLUTE=0
else
  BUILD_ABSOLUTE=1
fi


ssh_config_filename="ssh_config"
sshd_config_filename="sshd_config"
openssh_config_dirspec="$extended_sysconfdir"
ssh_config_filespec="${openssh_config_dirspec}/$ssh_config_filename"
sshd_config_filespec="${openssh_config_dirspec}/$sshd_config_filename"

ssh_confd_dirspec="$extended_sysconfdir/ssh_config.d"
sshd_confd_dirspec="$extended_sysconfdir/sshd_config.d"

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-settings-ssh-common.sh"
rm -f "$FILE_SETTINGS_FILESPEC"

echo "Detected $ID distro."

case $ID in
  debian|devuan)
    USER_NAME="ssh"
    GROUP_NAME="ssh"
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
    systemd_unitname="TBD"
    sysvinit_unitname="TBD"
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

flex_mkdir "$sysconfdir"
flex_mkdir "$extended_sysconfdir"
if [ "$HAS_SSHD_CONFIG_D" -ne 0 ]; then
  flex_mkdir "$sshd_configd_dirspec"
fi

if [ "$HAS_SSH_CONFIG_D" -ne 0 ]; then
  flex_mkdir "$ssh_configd_dirspec"
fi

ssh_bin_filespec="$( whereis ssh | awk '{print $2}')"
sshd_bin_filespec="$( whereis sshd | awk '{print $2}')"


sshd_home_dirspec="$( egrep "^${SSHD_USER_NAME}:" /etc/passwd | awk -F: '{print $6 }')"
echo "sshd_home_dirspec: $sshd_home_dirspec"

