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
VAR_CACHE_DIRSPEC="${VAR_DIRSPEC}/cache"

# systemd
ETC_SYSTEMD_DIRSPEC="/etc/systemd"
ETC_SYSTEMD_SYSTEM_DIRSPEC="/etc/systemd/system"

# Distro-specifics

source /etc/os-release
DEFAULT_ETC_CONF_DIRNAME="${DEFAULT_ETC_CONF_DIRNAME:-}"

case $ID in
  debian|devuan)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR=""
    DEFAULT_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    WHEEL_GROUP="sudo"
    ;;
  fedora|centos|redhat)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR="/var"
    DEFAULT_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    WHEEL_GROUP="wheel"
    ;;
  arch)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR="/var"
    DEFAULT_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
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

VAR_LIB_DIRSPEC="${VAR_DIRSPEC}/lib"
