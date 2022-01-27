# 
# File: distro-os.sh
# Title: Determine OS distro and their directory specifications
#
#   DEFAULT_PKG_NAME=
#   DEFAULT_ETC_CONF_DIRNAME=
#

# POSIX unix

VAR_DIRSPEC="/var"
USR_DIRSPEC="/usr"
ETC_DIRSPEC="/etc"


# Distro-specifics

source /etc/os-release
DEFAULT_ETC_CONF_DIRNAME="${DEFAULT_ETC_CONF_DIRNAME:-}"

case $ID in
  debian|devuan)
    DISTRO_PREFIX=""
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR=""
    DISTRO_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    CHRONYD_USER_NAME="_chrony"
    CHRONYD_GROUP_NAME="_chrony"
    WHEEL_GROUP="sudo"
    ;;
  centos)
    DISTRO_PREFIX=""
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR="/var"
    DISTRO_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    CHRONYD_USER_NAME="chrony"
    CHRONYD_GROUP_NAME="chrony"
    WHEEL_GROUP="wheel"
    ;;
  redhat)
    DISTRO_PREFIX=""
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR="/var"
    DISTRO_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    CHRONYD_USER_NAME="chrony"
    CHRONYD_GROUP_NAME="chrony"
    WHEEL_GROUP="wheel"
    ;;
  fedora)
    DISTRO_PREFIX=""
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR="/var"
    DISTRO_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    CHRONYD_USER_NAME="chrony"
    CHRONYD_GROUP_NAME="chrony"
    WHEEL_GROUP="wheel"
    ;;
  arch)
    DISTRO_PREFIX=""
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR="/var"
    DISTRO_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    CHRONYD_USER_NAME="chrony"
    CHRONYD_GROUP_NAME="chrony"
    WHEEL_GROUP="wheel"
    ;;
  *)
    echo "Unknown Linux distro"
    exit 3
    ;;
esac

# Vendor-specific autotool/autoconf
prefix="${prefix:-${DISTRO_PREFIX}}"
sysconfdir="${sysconfdir:-${DISTRO_SYSCONFDIR}}"
exec_prefix="${exec_prefix:-${DISTRO_EXEC_PREFIX}}"
libdir="${libdir:-"${exec_prefix}/lib"}"
libexecdir="${libexecdir:-"${exec_prefix}/libexec"}"
localstatedir="${localstatedir:-"$DISTRO_LOCALSTATEDIR"}"
datarootdir="${datarootdir:-"${prefix}/share"}"
sharedstatedir="${sharedstatedir:-"${prefix}/com"}"
bindir="${bindir:-"${exec_prefix}/bin"}"
sbindir="${sbindir:-"${exec_prefix}/sbin"}"
rundir="${rundir:-"${localstatedir}/run"}"

# package maintainer-specific goes into outside bash script

