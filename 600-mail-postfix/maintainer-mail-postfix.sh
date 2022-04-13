#!/bin/bash
# File: maintainer-mail-postfix.sh
# Title: Common settings for Postfix mail server
#
# *_PTYPE is listed in `postconf -m`; current available 
# options are: btree cidr environ fail hash inline 
#              internal memcache nis pipemap proxy 
#              randmap regexp socketmap static tcp 
#              texthash unionmap unix
#
# Definable ENV variables
#   BUILDROOT
#   CHROOT_DIR
#   INSTANCE
#   VAR_LIB_POSTFIX_DIRNAME - useful for multi-instances of 'postfix' daemons

CHROOT_DIR="${CHROOT_DIR:-}"
BUILDROOT="${BUILDROOT:-build}"
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

extracted_dirspec="$(dirname $(realpath $0))"
set
echo "PWD: $PWD"
echo "CWD: $CWD"
echo "extracted_disrspec: $extracted_dirspec"


source ../easy-admin-installer.sh

SYSD_BIND_TEMPLATE_SVCNAME="postfix"
SYSD_BIND_SVCNAME="postfix"

source ../distro-os.sh

POSTFIX_CONF_FILETYPE=".cf"

MAIN_CF_FILEPART="main"
MAIN_CF_FILETYPE="$POSTFIX_CONF_FILETYPE"
MAIN_CF_FILENAME="${MAIN_CF_FILEPART}${MAIN_CF_FILETYPE}"

MASTER_CF_FILEPART="main"
MASTER_CF_FILETYPE="$POSTFIX_CONF_FILETYPE"
MASTER_CF_FILENAME="${MASTER_CF_FILEPART}${MASTER_CF_FILETYPE}"

case $ID in
  debian|devuan)
    USER_NAME="postfix"
    GROUP_NAME="postfix"
    ETC_SUB_DIRNAME="postfix"
    VAR_LIB_SUB_DIRNAME="postfix"
    VAR_SPOOL_SUB_DIRNAME="postfix"
    DISTRO_HOME_DIRSPEC="/var/spool/$USER_NAME"
    package_tarname="postfix"
    default_chroot_dirspec="$DISTRO_HOME_DIRSPEC"
    systemd_unitname="postfix"
    ;;
  fedora|centos|redhat)
    USER_NAME="postfix"
    GROUP_NAME="postfix"
    ETC_SUB_DIRNAME="postfix"
    VAR_LIB_SUB_DIRNAME="postfix"
    VAR_SPOOL_SUB_DIRNAME="postfix"
    DISTRO_HOME_DIRSPEC="/var/spool/$USER_NAME"
    package_tarname="postfix"
    default_chroot_dirspec="$DISTRO_HOME_DIRSPEC"
    systemd_unitname="postfix"
    ;;
  arch)
    USER_NAME="postfix"
    GROUP_NAME="postfix"
    ETC_SUB_DIRNAME="postfix"
    VAR_LIB_SUB_DIRNAME="postfix"
    VAR_SPOOL_SUB_DIRNAME="postfix"
    DISTRO_HOME_DIRSPEC="/var/spool/$USER_NAME"
    package_tarname="postfix"
    default_chroot_dirspec="$DISTRO_HOME_DIRSPEC"
    systemd_unitname="postfix"
    ;;
esac

if [ -n "$ETC_SUB_DIRNAME" ]; then
  extended_sysconfdir="${sysconfdir}/${ETC_SUB_DIRNAME}"
else
  extended_sysconfdir="${sysconfdir}"
fi
ETC_POSTFIX_DIRSPEC="$extended_sysconfdir"
POSTFIX_CONF_FILESPEC="${ETC_POSTFIX_DIRSPEC}/${POSTFIX_CONF_FILENAME}"
SYSTEMD_POSTFIX_UNITNAME="$systemd_unitname"

SYSTEMD_POSTFIX_SERVICE="${SYSTEMD_POSTFIX_UNITNAME}.$SYSTEMD_SERVICE_FILETYPE"

# Now ensure that we use the same tools as  this daemon
POSTFIX_SBIN_DIRSPEC="$(dirname "$postfix_bin")"
TOOL_DIRSPEC="$(dirname "$POSTFIX_SBIN_DIRSPEC")"

postfix_sbin_filespec="${POSTFIX_SBIN_DIRSPEC}/postfix"
postfix_postconf_sbin_filespec="${POSTFIX_SBIN_DIRSPEC}/postconf"
postfix_bin_dirspec="${TOOL_DIRSPEC}/bin"

# Distro-specific?
POSTFIX_INIT_DEFAULT_FILENAME="${sysvinit_unitname}"

#!/bin/bash

ETC_DIRSPEC="/etc"
POSTFIX_DIRNAME="postfix"
POSTFIX_DIRSPEC="/etc/$POSTFIX_DIRNAME"
INSTALL_POSTFIX_DIRSPEC="${BUILDROOT}${CHROOT_DIR}/etc/$POSTFIX_DIRNAME"

MAIN_CF_DIRSPEC="${POSTFIX_DIRSPEC}"
MAIN_CF_FILESPEC="${MAIN_CF_DIRSPEC}/$MAIN_CF_FILENAME"

MASTER_CF_DIRSPEC="${POSTFIX_DIRSPEC}"
MASTER_CF_FILESPEC="${MASTER_CF_DIRSPEC}/$MASTER_CF_FILENAME"

ACCESS_FILENAME="access"
ACCESS_DIRSPEC="${POSTFIX_DIRSPEC}"
ACCESS_FILESPEC="${ACCESS_DIRSPEC}/$ACCESS_FILENAME"

ALIASES_FILENAME="aliases"
ALIASES_DIRSPEC="${POSTFIX_DIRSPEC}"
ALIASES_FILESPEC="${ALIASES_DIRSPEC}/$ALIASES_FILENAME"

CANONICAL_FILENAME="canonical"
CANONICAL_DIRSPEC="${POSTFIX_DIRSPEC}"
CANONICAL_FILESPEC="${CANONICAL_DIRSPEC}/$CANONICAL_FILENAME"

RELOCATED_FILENAME="relocated"
RELOCATED_DIRSPEC="${POSTFIX_DIRSPEC}"
RELOCATED_FILESPEC="${RELOCATED_DIRSPEC}/$RELOCATED_FILENAME"

TRANSPORT_FILENAME="transport"
TRANSPORT_DIRSPEC="${POSTFIX_DIRSPEC}"
TRANSPORT_FILESPEC="${TRANSPORT_DIRSPEC}/$TRANSPORT_FILENAME"


VIRTUAL_FILENAME="virtual"
VIRTUAL_DIRSPEC="${POSTFIX_DIRSPEC}"
VIRTUAL_FILESPEC="${VIRTUAL_DIRSPEC}/$VIRTUAL_FILENAME"

SASL_DIRNAME="sasl"
SASL_DIRSPEC="${POSTFIX_DIRSPEC}/$SASL_DIRNAME"

SASL_DIRNAME="sasl"
SASL_DIRSPEC="${POSTFIX_DIRSPEC}/$SASL_DIRNAME"

SASL_SMTPD_CONF_FILEPART="smtpd"
SASL_SMTPD_CONF_FILETYPE=".conf"
SASL_SMTPD_CONF_FILENAME="${SASL_SMTPD_CONF_FILEPART}$SASL_SMTPD_CONF_FILETYPE"
SASL_SMTPD_CONF_FILESPEC="${SASL_DIRSPEC}/$SASL_SMTPD_CONF_FILENAME"

DATA_DIRSPEC="${VAR_LIB_DIRSPEC}/postfix"

ADDR_VERIFY_MAP_PTYPE="hash:"
ADDR_VERIFY_MAP_FILENAME="verify"
ADDR_VERIFY_MAP_DIRSPEC="$DATA_DIRSPEC"
ADDR_VERIFY_MAP_FILESPEC="${ADDR_VERIFY_MAP_DIRSPEC}/$ADDR_VERIFY_MAP_FILENAME"
ADDR_VERIFY_MAP_POSTSPEC="${ADDR_VERIFY_MAP_PTYPE}${ADDR_VERIFY_MAP_FILESPEC}"

ALIAS_MAPS_PTYPE=""  # plaintext file
ALIAS_MAPS_FILENAME="aliases"
ALIAS_MAPS_DIRSPEC="$ETC_DIRSPEC"
ALIAS_MAPS_FILESPEC="${ALIAS_MAPS_DIRSPEC}/$ALIAS_MAPS_FILENAME"
ALIAS_MAPS_POSTSPEC="${ALIAS_MAPS_PTYPE}${ALIAS_MAPS_FILESPEC}"

