# 
# File: distro-os.sh
# Title: Determine OS distro and their directory specifications
#
#   DEFAULT_PKG_NAME=
#   DEFAULT_ETC_CONF_DIRNAME=
#
# Importable environment names
#   prefix
#   sysconfdir
#   exec_prefix
#   libdir
#   libexecdir
#   localstatedir
#   datarootdir
#   sharestatedir
#   bindir
#   sbindir
#   rundir
#

VAR_DIRSPEC="/var"
# shellcheck disable=SC2034
USR_DIRSPEC="/usr"
# shellcheck disable=SC2034
ETC_DIRSPEC="/etc"
# shellcheck disable=SC2034
VAR_CACHE_DIRSPEC="${VAR_DIRSPEC}/cache"
# shellcheck disable=SC2034
VAR_LIB_DIRSPEC="${VAR_DIRSPEC}/lib"
# shellcheck disable=SC2034
USR_LIB_DIRSPEC="${USR_DIRSPEC}/lib"

# systemd
# systemd service filetype
SYSTEMD_SERVICE_FILETYPE="service"
# shellcheck disable=SC2034
ETC_SYSTEMD_DIRSPEC="/etc/systemd"
# shellcheck disable=SC2034
ETC_SYSTEMD_SYSTEM_DIRSPEC="/etc/systemd/system"

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
    WHEEL_GROUP="sudo"
    ;;
  fedora|centos|redhat)
    DISTRO_PREFIX=""
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR="/var"
    DISTRO_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    WHEEL_GROUP="wheel"
    ;;
  arch)
    DISTRO_PREFIX=""
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR="/var"
    DISTRO_SYSCONFDIR="/etc"
    DEFAULT_EXTENDED_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
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

VAR_LIB_DIRSPEC="${VAR_DIRSPEC}/lib"
