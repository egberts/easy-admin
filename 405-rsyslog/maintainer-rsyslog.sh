#
# File: maintainer-rsyslog.sh
# Title: Common settings for RSysLog
# Description:
#
# importable environment name



CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

source ../easy-admin-installer.sh
source ../distro-os.sh
ID=${TEST_ID:-${ID}}
RSYSLOG_CONF_FILENAME="rsyslog.conf"
SPOOL_RSYSLOG_DIRNAME="rsyslog"
LOG_RSYSLOG_FILENAME="syslog"
LOG_RSYSLOG_FILENAMES="auth cron kern mail user"

case $ID in
  debian|devuan)
    ETC_RSYSLOG_DIRSPEC="$sysconfdir"
    RSYSLOG_CONF_FILESPEC="${ETC_RSYSLOG_DIRSPEC}/$RSYSLOG_CONF_FILENAME"
    RSYSLOGD_CONF_SUBDIRNAME="rsyslog.d"
    ETC_RSYSLOGD_DIRSPEC="${ETC_RSYSLOG_DIRSPEC}/$RSYSLOGD_CONF_SUBDIRNAME"
    SPOOL_RSYSLOG_DIRSPEC="${VAR_DIRSPEC}/spool/$SPOOL_RSYSLOG_DIRNAME"
    LOG_RSYSLOG_DIRSPEC="${VAR_DIRSPEC}/log"
    LOG_RSYSLOG_FILESPEC="${LOG_RSYSLOG_DIRSPEC}/syslog"
    USER_NAME="root"
    GROUP_NAME="adm"
    package_tarname="rsyslog"
    ;;
  fedora|centos|redhat)
    ETC_RSYSLOG_DIRSPEC="$sysconfdir/rsyslog"
    RSYSLOG_CONF_FILESPEC="${ETC_RSYSLOG_DIRSPEC}/$RSYSLOG_CONF_FILENAME"
    RSYSLOGD_CONF_SUBDIRNAME="rsyslog.d"
    ETC_RSYSLOGD_DIRSPEC="${ETC_RSYSLOG_DIRSPEC}/$RSYSLOGD_CONF_SUBDIRNAME"
    SPOOL_RSYSLOG_DIRSPEC="${VAR_DIRSPEC}/spool/$SPOOL_RSYSLOG_DIRNAME"
    LOG_RSYSLOG_DIRSPEC="${VAR_DIRSPEC}/log/$LOG_RSYSLOG_FILENAME"
    LOG_RSYSLOG_FILESPEC="${LOG_RSYSLOG_DIRSPEC}/syslog"
    USER_NAME="root"
    GROUP_NAME="adm"
    package_tarname="rsyslog"
    ;;
  arch)
    ETC_RSYSLOG_DIRSPEC="$sysconfdir/rsyslog"
    RSYSLOG_FILESPEC="${ETC_RSYSLOG_DIRSPEC}/$RSYSLOG_CONF_FILENAME"
    RSYSLOGD_CONF_SUBDIRNAME="rsyslog.d"
    ETC_RSYSLOGD_DIRSPEC="${ETC_RSYSLOG_DIRSPEC}/$RSYSLOGD_CONF_SUBDIRNAME"
    SPOOL_RSYSLOG_DIRSPEC="${VAR_DIRSPEC}/spool/$SPOOL_RSYSLOG_DIRNAME"
    LOG_RSYSLOG_DIRSPEC="${VAR_DIRSPEC}/log"
    LOG_RSYSLOG_FILESPEC="${LOG_RSYSLOG_DIRSPEC}/syslog"
    USER_NAME="root"
    GROUP_NAME="adm"
    package_tarname="rsyslog"
    ;;
  *)
    echo "Unknown Linux OS distro: '$ID'; aborted."
    exit 3
esac

if [ -n "$ETC_RSYSLOG_DIRSPEC" ]; then
  extended_sysconfdir="${ETC_RSYSLOGD_DIRSPEC}"
else
  extended_sysconfdir="$sysconfdir"
fi

# Instantiations
