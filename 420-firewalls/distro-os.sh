#
# File: distro-os.sh
# Title: Determine OS distro
#
#   DEFAULT_PKG_NAME=
#   DEFAULT_ETC_CONF_DIRNAME=
#
DEFAULT_ETC_CONF_DIRNAME="${DEFAULT_ETC_CONF_DIRNAME:-}"

source /etc/os-release

case $ID in
  debian|devuan)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR=""
    DEFAULT_SYSCONFDIR="/etc"
    if [ -z "${DEFAULT_ETC_CONF_DIRNAME}" ] \
       || [ "${DEFAULT_ETC_CONF_DIRNAME:0:1}" == '/' ]; then
      DEFAULT_PKG_SYSCONFDIR="/etc${DEFAULT_ETC_CONF_DIRNAME}"
    else
      DEFAULT_PKG_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    fi
    # No USER_NAME
    # No GROUP_NAME
    ;;
  redhat|centos|fedora)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR="/var"
    DEFAULT_SYSCONFDIR="/etc"
    if [ -z "${DEFAULT_ETC_CONF_DIRNAME}" ] \
       || [ "${DEFAULT_ETC_CONF_DIRNAME:0:1}" == '/' ]; then
      DEFAULT_PKG_SYSCONFDIR="/etc${DEFAULT_ETC_CONF_DIRNAME}"
    else
      DEFAULT_PKG_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    fi
    # No USER_NAME
    # No GROUP_NAME
    ;;
  arch)
    DEFAULT_PREFIX=""
    DEFAULT_EXEC_PREFIX="/usr"
    DEFAULT_LOCALSTATEDIR=""
    DEFAULT_SYSCONFDIR="/etc"
    if [ -z "${DEFAULT_ETC_CONF_DIRNAME}" ] \
       || [ "${DEFAULT_ETC_CONF_DIRNAME:0:1}" == '/' ]; then
      DEFAULT_PKG_SYSCONFDIR="/etc${DEFAULT_ETC_CONF_DIRNAME}"
    else
      DEFAULT_PKG_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
    fi
    # No USER_NAME
    # No GROUP_NAME
    ;;
  *)
    echo "Unknown Linux distro"
    exit 3
    ;;
esac

# Vendor-specific autotool/autoconf
prefix="${prefix:-${DISTRO_PREFIX}}"
sysconfdir="${sysconfdir:-${DISTRO_SYSCONFDIR}}"
extended_sysconfdir="${extended_sysconfdir:-${DEFAULT_PKG_SYSCONFDIR}}"
exec_prefix="${exec_prefix:-${prefix:-$DISTRO_EXEC_PREFIX}}"
libdir="${libdir:-"${exec_prefix}/lib"}"
libexecdir="${libexecdir:-"${exec_prefix}/libexec"}"
localstatedir="${localstatedir:-"$DISTRO_LOCALSTATEDIR"}"
datarootdir="${datarootdir:-"${prefix}/share"}"
sharedstatedir="${sharedstatedir:-"${prefix}/com"}"
bindir="${bindir:-"${exec_prefix}/bin"}"
sbindir="${bindir:-"${exec_prefix}/sbin"}"
rundir="${rundir:-"${localstatedir}/run"}"

# Package maintainer-specific

