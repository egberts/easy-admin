#
# File: chrony-ntp-common.sh
# Title: Package Maintainer-specific settings for Chrony NTP server

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

source installer.sh

DEFAULT_ETC_CONF_DIRNAME="chrony"  # feeds into DEFAULT_EXTENDED_SYSCONFDIR in os-distro.sh

source os-distro.sh

extended_sysconfdir="${extended_sysconfdir:-${DEFAULT_EXTENDED_SYSCONFDIR}}"


if [ "${BUILDROOT:0:1}" != '/' ]; then
  # relative build, create subdirectories
  # absolute build, do not create build directory
  if [ ! -d "$BUILDROOT" ]; then
    mkdir -p "$BUILDROOT"
  fi
  mkdir -p "${BUILDROOT}$extended_sysconfdir"
  BUILD_ABSOLUTE=0
else
  BUILD_ABSOLUTE=1
fi


# Package maintainer-specific

case $ID in
  debian|devuan)
    package_name="chrony"
    chrony_systemd_unit_name="chrony.service"
    CHRONYD_USER_NAME="_chrony"
    CHRONYD_GROUP_NAME="_chrony"
    ;;
  fedora)
    package_name="chrony"
    chrony_systemd_unit_name="chronyd.service"
    CHRONYD_USER_NAME="chrony"
    CHRONYD_GROUP_NAME="chrony"
    ;;
  redhat)
    package_name="chrony"
    chrony_systemd_unit_name="chronyd.service"
    CHRONYD_USER_NAME="chrony"
    CHRONYD_GROUP_NAME="chrony"
    ;;
  centos)
    package_name="chrony"
    chrony_systemd_unit_name="chronyd.service"
    CHRONYD_USER_NAME="chrony"
    CHRONYD_GROUP_NAME="chrony"
    ;;
  arch)
    package_name="chrony"
    chrony_systemd_unit_name="chronyd.service"
    CHRONYD_USER_NAME="chrony"
    CHRONYD_GROUP_NAME="chrony"
    ;;
  *)
    echo "Unknown $ID distro; aborting..."
    exit 1
    ;;
esac

LOG_DIRSPEC="${VAR_DIRSPEC}/log"  # /var/log

DEFAULT_CHRONY_CONFD_DIRNAME="conf.d"
DEFAULT_CHRONY_SOURCESD_DIRNAME="sources.d"
FILETYPE_SOURCES="sources"  # compiled into code

DEFAULT_CHRONY_CONF_FILENAME="chrony.conf"
DEFAULT_CHRONY_KEYS_FILENAME="chrony.keys"
DEFAULT_CHRONY_DRIFT_FILENAME="chrony.drift"

# /etc/chrony/chrony.conf
CHRONY_CONF_FILESPEC="${extended_sysconfdir}/$DEFAULT_CHRONY_CONF_FILENAME"

varlibdir="${localstatedir}/lib"
CHRONY_VAR_LIB_DIRSPEC="${varlibdir}/$DEFAULT_ETC_CONF_DIRNAME"

CHRONY_CONFD_DIRSPEC="${extended_sysconfdir}/$DEFAULT_CHRONY_CONFD_DIRNAME"  # /etc/chrony/conf.d
CHRONY_SOURCESD_DIRSPEC="${extended_sysconfdir}/$DEFAULT_CHRONY_SOURCESD_DIRNAME"  # /etc/chrony/sources.d
CHRONY_KEYS_FILESPEC="${extended_sysconfdir}/$DEFAULT_CHRONY_KEYS_FILENAME"

# Useful directories that autoconf/configure/autoreconf does not offer.
CHRONY_RUN_DIRSPEC="${rundir}/$package_name"  # /run/chrony

CHRONY_LOG_DIRSPEC="$LOG_DIR/chrony"  # /var/log/chrony

CHRONY_VAR_LIB_DIRSPEC="${varlibdir}/$package_name"
CHRONY_DRIFT_FILESPEC="${CHRONY_VAR_LIB_DIRSPEC}/$DEFAULT_CHRONY_DRIFT_FILENAME"

# A file in $CHRONY_DHCP_DIRSPEC is written by
# the dhclient-exit-hooks.d/chrony script and is include-read by
# chrony.conf config file, 'sourcedir' config item, or
# Debian's dynamic '/run/chrony-dhcp'
CHRONY_DHCP_DIRSPEC="$(realpath -m "$rundir/chrony-dhcp")"


unset varlibdir

