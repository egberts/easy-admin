#
# File: maintainer-lighttpd.sh
# Title: Common settings for LigHTTPd Web Server
# Description:
#
# importable environment name
#   INSTANCE - a specific instance out of multiple instances of LightHTTPD server daemons
#
# Debian/Deuvan
# $ tree -pug /etc/lighttpd
# [drwxr-xr-x root     root    ]  /etc/lighttpd
# ├── [drwxr-xr-x root     root    ]  conf-available
# │   ├── [-rw-r--r-- root     root    ]  05-auth.conf
# │   ├── [-rw-r--r-- root     root    ]  05-setenv.conf
# │   ├── [-rw-r--r-- root     root    ]  10-accesslog.conf
# │   ├── [-rw-r--r-- root     root    ]  10-cgi.conf
# │   ├── [-rw-r--r-- root     root    ]  10-dir-listing.conf
# │   ├── [-rw-r--r-- root     root    ]  10-evhost.conf
# │   ├── [-rw-r--r-- root     root    ]  10-expire.conf
# │   ├── [-rw-r--r-- root     root    ]  10-fastcgi.conf
# │   ├── [-rw-r--r-- root     root    ]  10-no-www.conf
# │   ├── [-rw-r--r-- root     root    ]  10-proxy.conf
# │   ├── [-rw-r--r-- root     root    ]  10-rewrite.conf
# │   ├── [-rw-r--r-- root     root    ]  10-rrdtool.conf
# │   ├── [-rw-r--r-- root     root    ]  10-simple-vhost.conf
# │   ├── [-rw-r--r-- root     root    ]  10-sockproxy.conf
# │   ├── [-rw-r--r-- root     root    ]  10-ssi.conf
# │   ├── [-rw-r--r-- root     root    ]  10-ssl.conf
# │   ├── [-rw-r--r-- root     root    ]  10-status.conf
# │   ├── [-rw-r--r-- root     root    ]  10-userdir.conf
# │   ├── [-rw-r--r-- root     root    ]  11-extforward.conf
# │   ├── [-rw-r--r-- root     root    ]  15-fastcgi-php.conf
# │   ├── [-rw-r--r-- root     root    ]  15-fastcgi-php-fpm.conf
# │   ├── [-rw-r--r-- root     root    ]  20-deflate.conf
# │   ├── [-rw-r--r-- root     root    ]  90-debian-doc.conf
# │   ├── [-rw-r--r-- root     root    ]  90-javascript-alias.conf
# │   ├── [-rw-r--r-- root     root    ]  99-unconfigured.conf
# │   └── [-rw-r--r-- root     root    ]  README
# ├── [drwxr-xr-x root     root    ]  conf-enabled
# │   └── [lrwxrwxrwx root     root    ]  90-javascript-alias.conf -> ../conf-available/90-javascript-alias.conf
# └── [-rw-r--r-- root     root    ]  lighttpd.conf
#
# 3 directories, 28 files


DISTDIR="${DISTDIR}:-"
CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"

source ../easy-admin-installer.sh
source ../distro-os.sh

# Posix
ETC_DIRSPEC="${DISTDIR}${CHROOT_DIR}/etc"
USR_DIRSPEC="${DISTDIR}${CHROOT_DIR}/usr"
RUN_DIRSPEC="${DISTDIR}${CHROOT_DIR}/run"
VAR_DIRSPEC="${DISTDIR}${CHROOT_DIR}/var"

LOG_DIRSPEC="${VAR_DIRSPEC}/log"


case $ID in
  debian|devuan)
    package_tarname="lighttpd"

    GENERIC_LIGHTTPD_NAME="lighttpd"
    LIGHTTPD_CONFIG_FILENAME="${GENERIC_LIGHTTPD_NAME}"
    LIGHTTPD_CONFIG_FILETYPE=".conf"
    LIGHTTPD_CONFIG_FILESPEC="${LIGHTTPD_CONFIG_FILENAME}.${LIGHTTPD_CONFIG_FILETYPE}"

    LIGHTTPD_ETC_DIRSPEC="${ETC_DIRSPEC}/$GENERIC_LIGHTTPD_NAME"
    LIGHTTPD_ETC_CONF_ENABLED_DIRSPEC="${LIGHTTPD_ETC_DIRSPEC}/conf-enabled"
    LIGHTTPD_ETC_CONF_HOLD_DIRSPEC="${LIGHTTPD_ETC_DIRSPEC}/conf-available"

    LIGHTTPD_MODULES_DIRSPEC="${USR_DIRSPEC}/lib/${GENERIC_LIGHTTPD_NAME}"

    LIGHTTPD_RUN_DIRSPEC="${RUN_DIRSPEC}/${GENERIC_LIGHTTPD_NAME}"
    LIGHTTPD_STATE_DIRSPEC="${LIGHTTPD_RUN_DIRSPEC}"
    LIGHTTPD_PID_FILESPEC="${RUN_DIRSPEC}/${GENERIC_LIGHTTPD_NAME}.pid"
    LIGHTTPD_LOCK_FILEPATH=

    LIGHTTPD_LOG_DIRSPEC="${LOG_DIRSPEC}/${GENERIC_LIGHTTPD_FILE}"
    LIGHTTPD_DOC_SERVER_ROOT_DIRSPEC="${VAR_DIRSPEC}/www/html"

    # # Debian/Ubuntu
    # dpkg -L lighttpd | xargs stat -c "%U:%G %a %n" 2>/dev/null
    LIGHTTPD_CONFIG_USER_NAME="root"
    LIGHTTPD_CONFIG_GROUP_NAME="root"
    LIGHTTPD_CONFIG_DIRSPEC_PERMS="0755"
    LIGHTTPD_CONFIG_FILESPEC_PERMS="0644"
    LIGHTTPD_DOCROOT_USER_NAME="root"
    LIGHTTPD_DOCROOT_GROUP_NAME="root"
    LIGHTTPD_DOCROOT_DIRSPEC_PERMS="0755"
    LIGHTTPD_LOG_USER_NAME="www-data"
    LIGHTTPD_LOG_GROUP_NAME="adm"
    LIGHTTPD_LOG_DIRSPEC_PERMS="0750"
    # However, user/group for web pages are www-data:www-data
    LIGHTTPD_TMP_DIRSPEC="${VAR_DIRSPEC}/tmp"
    ;;

  fedora|centos|redhat)
    package_tarname="lighttpd"

    GENERIC_LIGHTTPD_NAME="lighttpd"
    LIGHTTPD_CONFIG_FILENAME="${GENERIC_LIGHTTPD_NAME}"
    LIGHTTPD_CONFIG_FILETYPE=".conf"
    LIGHTTPD_CONFIG_FILESPEC="${LIGHTTPD_CONFIG_FILENAME}.${LIGHTTPD_CONFIG_FILETYPE}"

    LIGHTTPD_ETC_DIRSPEC="${ETC_DIRSPEC}/$GENERIC_LIGHTTPD_NAME"
    LIGHTTPD_ETC_CONF_ENABLED_DIRSPEC="${LIGHTTPD_ETC_DIRSPEC}/conf.d"
    # no holding pattern for /etc/lighttpd/conf.d (like Debain's conf.available/)

    LIGHTTPD_MODULES_DIRSPEC="${USR_DIRSPEC}/lib64/${GENERIC_LIGHTTPD_NAME}"

    LIGHTTPD_RUN_DIRSPEC="${RUN_DIRSPEC}/${GENERIC_LIGHTTPD_NAME}"
    LIGHTTPD_STATE_DIRSPEC="${LIGHTTPD_RUN_DIRSPEC}"
    LIGHTTPD_PID_FILEPATH="${RUN_DIRSPEC}/${GENERIC_LIGHTTPD_NAME}.pid"
    LIGHTTPD_LOCK_FILEPATH="${RUN_FILESPEC}/lock/${GENERIC_LIGHTTPD_NAME}"  # no filetype used

    LIGHTTPD_LOG_DIRSPEC="${LOG_DIRSPEC}/${GENERIC_LIGHTTPD_FILE}"
    LIGHTTPD_DOC_SERVER_ROOT_DIRSPEC="${VAR_DIRSPEC}/www/html"

    LIGHTTPD_TMP_DIRSPEC="${VAR_DIRSPEC}/tmp"

    # # RHEL/CentOS/Rocky
    # rpm -ql lighttpd | xargs stat -c "%U:%G %a %n" 2>/dev/null
    LIGHTTPD_CONFIG_USER_NAME="root"
    LIGHTTPD_CONFIG_GROUP_NAME="root"
    LIGHTTPD_CONFIG_DIRSPEC_PERMS="0755"
    LIGHTTPD_CONFIG_FILESPEC_PERMS="0644"
    LIGHTTPD_DOCROOT_USER_NAME="root"
    LIGHTTPD_DOCROOT_GROUP_NAME="root"
    LIGHTTPD_DOCROOT_DIRSPEC_PERMS="0755"
    LIGHTTPD_LOG_USER_NAME="lighttpd"
    LIGHTTPD_LOG_GROUP_NAME="lighttpd"
    LIGHTTPD_LOG_DIRSPEC_PERMS="0750"
    ;;
  arch)
    package_tarname="lighttpd"

    GENERIC_LIGHTTPD_NAME="lighttpd"
    LIGHTTPD_CONFIG_FILENAME="${GENERIC_LIGHTTPD_NAME}"
    LIGHTTPD_CONFIG_FILETYPE=".conf"
    LIGHTTPD_CONFIG_FILESPEC="${LIGHTTPD_CONFIG_FILENAME}.${LIGHTTPD_CONFIG_FILETYPE}"

    LIGHTTPD_ETC_DIRSPEC="${ETC_DIRSPEC}/$GENERIC_LIGHTTPD_NAME"
    LIGHTTPD_ETC_CONF_ENABLED_DIRSPEC="${LIGHTTPD_ETC_DIRSPEC}/conf.d"
    # no holding pattern for /etc/lighttpd/conf.d (like Debain's conf.available/)

    LIGHTTPD_MODULES_DIRSPEC="${USR_DIRSPEC}/lib/${GENERIC_LIGHTTPD_NAME}"

    LIGHTTPD_RUN_DIRSPEC="${RUN_DIRSPEC}/${GENERIC_LIGHTTPD_NAME}"
    LIGHTTPD_STATE_DIRSPEC="${LIGHTTPD_RUN_DIRSPEC}"
    LIGHTTPD_PID_FILEPATH="${RUN_DIRSPEC}/${GENERIC_LIGHTTPD_NAME}/${GENERIC_LIGHTTPD_NAME}.pid"
    LIGHTTPD_LOCK_FILEPATH=

    LIGHTTPD_LOG_DIRSPEC="${LOG_DIRSPEC}/${GENERIC_LIGHTTPD_FILE}"
    LIGHTTPD_DOC_SERVER_ROOT_DIRSPEC="${VAR_DIRSPEC}/www/html"

    LIGHTTPD_TMP_DIRSPEC="${VAR_DIRSPEC}/tmp"

    # # Arch Linux
    # pacman -Ql lighttpd | xargs stat -c "%U:%G %a %n" 2>/dev/null
    LIGHTTPD_CONFIG_USER_NAME="root"
    LIGHTTPD_CONFIG_GROUP_NAME="root"
    LIGHTTPD_CONFIG_DIRSPEC_PERMS="0755"
    LIGHTTPD_CONFIG_FILESPEC_PERMS="0644"
    LIGHTTPD_DOCROOT_USER_NAME="root"
    LIGHTTPD_DOCROOT_GROUP_NAME="root"
    LIGHTTPD_DOCROOT_DIRSPEC_PERMS="0755"
    LIGHTTPD_LOG_USER_NAME="http"
    LIGHTTPD_LOG_GROUP_NAME="http"
    LIGHTTPD_LOG_DIRSPEC_PERMS="0750"
    ;;
  *)
    echo "Unknown Linux OS distro: '$ID'; aborted."
    exit 3
esac

LIGHTTPD_CONFIG_FILEPATH="${LIGHTTPD_ETC_DIRSPEC}/${LIGHTTPD_CONFIG_FILESPEC}"

# Instantiations
