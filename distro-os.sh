#
# File: distro-os.sh
# Title: Determine OS distro and their directory specifications
#
#   prefix [/usr]
#   sysconfdir [/etc]
#   exec_prefix [/usr]
#   libdir [/var/lib]
#   DEFAULT_PKG_NAME=
#   DEFAULT_ETC_CONF_DIRNAME=
#
# POSIX unix

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

source /etc/os-release

# Probably should have 'source distro-package-specific' scripting go here
# Needs to deal with 'DEFAULT_ETC_CONF_DIRNAME' there.

# libdir and $HOME are two separate grouping (that Fedora, et. al. merged)
case $ID in
  debian|devuan)
    DISTRO_PREFIX="/usr"
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR=""
    DISTRO_SYSCONFDIR="/etc"
    DEFAULT_LIB_DIRSPEC="/var/lib"
    WHEEL_GROUP="sudo"
    ;;
  centos|fedora|redhat)
    DISTRO_PREFIX="/usr"
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR=""
    DISTRO_SYSCONFDIR="/etc"
    DEFAULT_LIB_DIRSPEC="/var"  # WTF?!
    WHEEL_GROUP="wheel"
    ;;
  arch)
    DISTRO_PREFIX=""
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR=""
    DISTRO_SYSCONFDIR="/etc"
    DEFAULT_LIB_DIRSPEC="/var"  # WTF?!
    WHEEL_GROUP="wheel"
    ;;
  *)
    echo "Unknown Operating System; undefined action; aborted."
    exit 3
    ;;
esac

DISTRO_ETC_DIRSPEC="$DISTRO_SYSCONFDIR"

# Vendor-specific autotool/autoconf,
# only set of violations of lowercase variable names crossing to other scripts
prefix="${prefix:-${DISTRO_PREFIX}}"
sysconfdir="${sysconfdir:-${DISTRO_SYSCONFDIR}}"
exec_prefix="${exec_prefix:-${prefix:-$DISTRO_EXEC_PREFIX}}"
libdir="${libdir:-$DEFAULT_LIB_DIRSPEC}"
libexecdir="${libexecdir:-"${exec_prefix}/libexec"}"
localstatedir="${localstatedir:-"$DISTRO_LOCALSTATEDIR"}"
datarootdir="${datarootdir:-"${prefix}/share"}"
sharedstatedir="${sharedstatedir:-"${prefix}/com"}"
bindir="${bindir:-"${exec_prefix}/bin"}"
sbindir="${sbindir:-"${exec_prefix}/sbin"}"
rundir="${rundir:-"${localstatedir}/run"}"

# Package maintainer-specific

