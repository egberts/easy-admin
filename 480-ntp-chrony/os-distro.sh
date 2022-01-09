# 
# File: os-distro.sh
# Title: Determine OS distro
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
  debian)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR=""
    DEFAULT_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    CHRONYD_USER_NAME="_chrony"
    CHRONYD_GROUP_NAME="_chrony"
    WHEEL_GROUP="sudo"
    ;;
  centos)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR="/var"
    DEFAULT_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    CHRONYD_USER_NAME="chrony"
    CHRONYD_GROUP_NAME="chrony"
    WHEEL_GROUP="wheel"
    ;;
  redhat)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR="/var"
    DEFAULT_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    CHRONYD_USER_NAME="chrony"
    CHRONYD_GROUP_NAME="chrony"
    WHEEL_GROUP="wheel"
    ;;
  fedora)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR="/var"
    DEFAULT_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    CHRONYD_USER_NAME="chrony"
    CHRONYD_GROUP_NAME="chrony"
    WHEEL_GROUP="wheel"
    ;;
  arch)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR="/var"
    DEFAULT_SYSCONFDIR="/etc"
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
prefix="${prefix:-${DEFAULT_PREFIX}}"
sysconfdir="${sysconfdir:-${DEFAULT_SYSCONFDIR}}"
exec_prefix="${exec_prefix:-${DEFAULT_EXEC_PREFIX}}"
libdir="${libdir:-"${exec_prefix}/lib"}"
libexecdir="${libexecdir:-"${exec_prefix}/libexec"}"
localstatedir="${localstatedir:-"$DEFAULT_LOCALSTATEDIR"}"
datarootdir="${datarootdir:-"${prefix}/share"}"
sharedstatedir="${sharedstatedir:-"${prefix}/com"}"
bindir="${bindir:-"${exec_prefix}/bin"}"
sbindir="${sbindir:-"${exec_prefix}/sbin"}"
rundir="${rundir:-"${localstatedir}/run"}"

# package maintainer-specific goes into outside bash script

