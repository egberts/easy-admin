#
# File: distro-os.sh
# Title: Determine OS distro
#
#   DEFAULT_PKG_NAME=
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
# shellcheck disable=SC2034
ETC_SYSTEMD_DIRSPEC="/etc/systemd"
# shellcheck disable=SC2034
ETC_SYSTEMD_SYSTEM_DIRSPEC="/etc/systemd/system"

# Distro-specifics
source /etc/os-release

case $ID in
  debian|devuan)
    DISTRO_PREFIX=""
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR=""
    DISTRO_ETC_DIRSPEC="/etc"

    WHEEL_GROUP="sudo"
    ;;
  centos|fedora|redhat)
    DISTRO_PREFIX=""
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR="/var"
    DISTRO_ETC_DIRSPEC="/etc"
    WHEEL_GROUP="wheel"
    ;;
  arch)
    DISTRO_PREFIX=""
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR="/var"
    DISTRO_ETC_DIRSPEC="/etc"
    WHEEL_GROUP="wheel"
    ;;
  *)
    echo "Unknown Linux OS distro: '$ID'; aborted."
    exit 3
    ;;
esac

DISTRO_SYSCONFDIR="${DISTRO_ETC_DIRSPEC}"


# Vendor-specific autotool/autoconf,
# only set of violations of lowercase variable names crossing to other scripts
prefix="${prefix:-${DISTRO_PREFIX}}"
sysconfdir="${sysconfdir:-${DISTRO_ETC_DIRSPEC}}"
exec_prefix="${exec_prefix:-${DISTRO_EXEC_PREFIX}}"
libdir="${libdir:-"${exec_prefix}/lib"}"
libexecdir="${libexecdir:-"${exec_prefix}/libexec"}"
localstatedir="${localstatedir:-"$DISTRO_LOCALSTATEDIR"}"
datarootdir="${datarootdir:-"${prefix}/share"}"
sharedstatedir="${sharedstatedir:-"${prefix}/com"}"
bindir="${bindir:-"${exec_prefix}/bin"}"
sbindir="${sbindir:-"${exec_prefix}/sbin"}"
rundir="${rundir:-"${localstatedir}/run"}"

# Package maintainer-specific

