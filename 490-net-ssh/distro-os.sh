#
# File: distro-os.sh
# Title: Determine OS distro
#
#   prefix [/usr]
#   sysconfdir [/etc]
#   exec_prefix [/usr]
#   libdir [/var/lib]
#   DEFAULT_PKG_NAME=
#   DEFAULT_ETC_CONF_DIRNAME=
#

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
    DISTRO_PREFIX="/usr"
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR=""
    DISTRO_SYSCONFDIR="/etc"
    DEFAULT_LIB_DIRSPEC="/var"  # WTF?!
    WHEEL_GROUP="wheel"
    ;;
  arch)
    DISTRO_PREFIX="/usr"
    DISTRO_EXEC_PREFIX="/usr"
    DISTRO_LOCALSTATEDIR=""
    DISTRO_SYSCONFDIR="/etc"
    DEFAULT_LIB_DIRSPEC="/var"  # WTF?!
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
libdir="${libdir:-"${DEFAULT_LIB_DIRSPEC}"}"
libexecdir="${libexecdir:-"${exec_prefix}/libexec"}"
localstatedir="${localstatedir:-"$DISTRO_LOCALSTATEDIR"}"
datarootdir="${datarootdir:-"${prefix}/share"}"
sharedstatedir="${sharedstatedir:-"${prefix}/com"}"
bindir="${bindir:-"${exec_prefix}/bin"}"
sbindir="${sbindir:-"${exec_prefix}/sbin"}"
rundir="${rundir:-"${localstatedir}/run"}"

# Package maintainer-specific

