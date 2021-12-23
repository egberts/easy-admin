#
# File: os-distro.sh
# Title: Determine OS distro
#
#   DEFAULT_PKG_NAME=
#   DEFAULT_ETC_CONF_DIRNAME=
#

source /etc/os-release

# Probably should have 'source distro-package-specific' scripting go here
# Needs to deal with 'DEFAULT_ETC_CONF_DIRNAME' there.
# Needs to deal with 'USER_NAME' there.
# Needs to deal with 'GROUP_NAME' there.

# libdir and $HOME are two separate grouping (that Fedora, et. al. merged)
case $ID in
  debian)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR=""
    DEFAULT_ETC_CONF_DIRNAME="${DEFAULT_ETC_CONF_DIRNAME:-bind}"
    DEFAULT_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    DEFAULT_LIB_NAMED_DIRNAME="${DEFAULT_LIB_CONF_DIRNAME:-bind}"
    DEFAULT_LIB_NAMED_DIRSPEC="/var/lib/${DEFAULT_LIB_NAMED_DIRNAME}"
    USER_NAME="bind"
    GROUP_NAME="bind"
    WHEEL_GROUP="sudo"
    ;;
  centos)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR="/var"
    DEFAULT_ETC_CONF_DIRNAME="${DEFAULT_ETC_CONF_DIRNAME:-named}"
    DEFAULT_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    DEFAULT_LIB_NAMED_DIRNAME="${DEFAULT_LIB_CONF_DIRNAME:-named}"
    DEFAULT_LIB_NAMED_DIRSPEC="/var/${DEFAULT_LIB_NAMED_DIRNAME}"
    USER_NAME="named"
    GROUP_NAME="named"
    WHEEL_GROUP="wheel"
    ;;
  redhat)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR="/var"
    DEFAULT_ETC_CONF_DIRNAME="${DEFAULT_ETC_CONF_DIRNAME:-named}"
    DEFAULT_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    DEFAULT_LIB_NAMED_DIRNAME="${DEFAULT_LIB_CONF_DIRNAME:-named}"
    DEFAULT_LIB_NAMED_DIRSPEC="/var/${DEFAULT_LIB_NAMED_DIRNAME}"
    USER_NAME="named"
    GROUP_NAME="named"
    WHEEL_GROUP="wheel"
    ;;
  fedora)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR="/var"
    DEFAULT_ETC_CONF_DIRNAME="${DEFAULT_ETC_CONF_DIRNAME:-named}"
    DEFAULT_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    DEFAULT_LIB_NAMED_DIRNAME="${DEFAULT_LIB_CONF_DIRNAME:-named}"
    DEFAULT_LIB_NAMED_DIRSPEC="/var/${DEFAULT_LIB_NAMED_DIRNAME}"
    USER_NAME="named"
    GROUP_NAME="named"
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
libdir="${libdir:-"${DEFAULT_LIB_NAMED_DIRSPEC}"}"
libexecdir="${libexecdir:-"${exec_prefix}/libexec"}"
localstatedir="${localstatedir:-"$DEFAULT_LOCALSTATEDIR"}"
datarootdir="${datarootdir:-"${prefix}/share"}"
sharedstatedir="${sharedstatedir:-"${prefix}/com"}"
bindir="${bindir:-"${exec_prefix}/bin"}"
sbindir="${sbindir:-"${exec_prefix}/sbin"}"
rundir="${rundir:-"${localstatedir}/run"}"

# Package maintainer-specific

