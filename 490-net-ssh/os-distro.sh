#
# File: os-distro.sh
# Title: Determine OS distro
#
#   DEFAULT_PKG_NAME=
#   DEFAULT_ETC_CONF_DIRNAME=
#
OS_TYPE="$(uname -s)"
DEFAULT_ETC_CONF_DIRNAME="${DEFAULT_ETC_CONF_DIRNAME:-}"

case $OS_TYPE in
  Linux)
    DISTRO_MANUF="$(lsb_release -s -i)"
    case $DISTRO_MANUF in
      Debian)
        DEFAULT_PREFIX=""
        DEFAULT_EXEC_PREFIX="/usr"
        DEFAULT_LOCALSTATEDIR=""
        DEFAULT_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
        # No USER_NAME
        # No GROUP_NAME
        ;;
      Redhat)
        DEFAULT_PREFIX=""
        DEFAULT_EXEC_PREFIX="/usr"
        DEFAULT_LOCALSTATEDIR="/var"
        DEFAULT_SYSCONFDIR="/etc/${DEFAULT_ETC_CONF_DIRNAME}"
        # No USER_NAME
        # No GROUP_NAME
        ;;
      *)
        echo "Unknown Linux distro"
        exit 3
        ;;
    esac
    ;;
  *)
    echo "Unknown Operating System; undefined action; aborted."
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
sbindir="${bindir:-"${exec_prefix}/sbin"}"
rundir="${rundir:-"${localstatedir}/run"}"

# Package maintainer-specific

