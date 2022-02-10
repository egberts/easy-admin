#!/bin/bash
# File: 514-dns-bind-logging.sh
# Title: Configure a 'logging' channel access for ISC Bind9 named daemon
#
# Description:
#
#   Creates /etc/bind/logging-named.conf
#

LOG_BACKUP_CNT=3
LOG_FILE_SIZE="5m"

# Used by 'named' and named.conf
LOGGING_NAMED_CONF_FILENAME="logging-named.conf"
CHANNEL_NAMED_CONF_FILENAME="logging-channels-named.conf"
CATEGORY_NAMED_CONF_FILENAME="logging-categories-named.conf"

echo "Create logging channel/category configuration files for ISC Bind9 named daemon"
echo

source ./maintainer-dns-isc.sh

INSTANCE_LOGGING_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/$LOGGING_NAMED_CONF_FILENAME"
INSTANCE_CHANNEL_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/$CHANNEL_NAMED_CONF_FILENAME"
INSTANCE_CATEGORY_NAMED_CONF_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/$CATEGORY_NAMED_CONF_FILENAME"

if [ "${BUILDROOT:0:1}" == '/' ]; then
  # absolute (rootfs?)
  echo "Absolute build"
else
  mkdir -p build
  FILE_SETTINGS_FILESPEC="${BUILDROOT}${CHROOT_DIR}/file-logging-named.sh"
  mkdir -p build/etc
  flex_mkdir "${ETC_NAMED_DIRSPEC}"
  if [ -n "$INSTANCE" ]; then
    flex_mkdir "${INSTANCE_ETC_NAMED_DIRSPEC}"
  fi
fi

# Generate generic `logging-named.conf`
# /etc/bind/logging-named.conf
filename="$(basename "$INSTANCE_LOGGING_NAMED_CONF_FILESPEC")"
filepath="$(dirname "$INSTANCE_LOGGING_NAMED_CONF_FILESPEC")"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/${filespec}"
cat << RNDC_LOGGING_CONF | tee "${BUILDROOT}${CHROOT_DIR}/$filespec" > /dev/null
#
# File: ${filename}
# Path: ${filepath}
# Title: Logging configuration file for ISC Bind9 named daemon
# Generator: $(basename "$0")
# Created on: $(date)
#
# To be included by: ${INSTANCE_NAMED_CONF_FILESPEC}
#
logging {

include "${INSTANCE_CHANNEL_NAMED_CONF_FILESPEC}";
include "${INSTANCE_CATEGORY_NAMED_CONF_FILESPEC}";

};
RNDC_LOGGING_CONF
flex_chmod 0640 "$filespec"
flex_chown "root:$GROUP_NAME" "$filespec"
echo

# Create the /etc/bind/logging-channels-named.conf
filename="$(basename "$INSTANCE_CHANNEL_NAMED_CONF_FILESPEC")"
filepath="$(dirname  "$INSTANCE_CHANNEL_NAMED_CONF_FILESPEC")"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$filespec ..."
cat << NAMED_CHANNEL_CONF | tee "${BUILDROOT}${CHROOT_DIR}/$filespec" > /dev/null
#
# File: ${filename}
# Path: ${filepath}
# Title: Provides logging channels configuration for ISC Bind9 named daemon
#
# Description:
#   Configures the location, level and type of logging that 
#   BIND performs. Unless you are using syslog you need a 
#   logging statement for BIND.
#   To be included by $INSTANCE_LOGGING_NAMED_CONF_FILESPEC file
#
# Generator: $(basename "$0")
# Created on: $(date)
#

    channel default_channel {
        file "/var/log/named/public/default.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 7;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel general_channel {
        file "/var/log/named/public/general.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 9;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel database_channel {
        file "/var/log/named/public/database.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel security_channel {
        file "/var/log/named/public/security.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 9;
        print-time yes;
        // print-severity true;
        // print-category true;
    };
    channel config_channel {
        file "/var/log/named/public/config.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel resolver_channel {
        file "/var/log/named/public/resolver.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 9;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel xfer-in_channel {
        file "/var/log/named/public/xfer-in.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 3;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel xfer-out_channel {
        file "/var/log/named/public/xfer-out.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 6;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel notify_channel {
        file "/var/log/named/public/notify.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        //severity dynamic;
        severity debug 3;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel client_channel {
        file "/var/log/named/public/client.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 9;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel unmatched_channel {
        file "/var/log/named/public/unmatched.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 3;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel queries_channel {
        file "/var/log/named/public/queries.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 9;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel query-errors_channel {
        file "/var/log/named/public/query-errors.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 9;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel network_channel {
        file "/var/log/named/public/network.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel update_channel {
        file "/var/log/named/public/update.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 9;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel update-security_channel {
        file "/var/log/named/public/update-security.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 9;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel dispatch_channel {
        file "/var/log/named/public/dispatch.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 3;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel dnssec_channel {
        file "/var/log/named/public/dnssec.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 3;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel lame-servers_channel {
        file "/var/log/named/public/lame-servers.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel delegation-only_channel {
        file "/var/log/named/public/delegation-only.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 3;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel rate-limit_channel {
        file "/var/log/named/public/rate-limit.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        print-time yes;
        print-severity true;
        print-category true;
    };
    channel audit_channel {
        file "/var/log/named/public/audit.log" versions $LOG_BACKUP_CNT size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 3;
        print-time yes;
        print-severity true;
        print-category true;
    };


NAMED_CHANNEL_CONF
flex_chmod 0640 "$filespec"
flex_chown "root:$GROUP_NAME" "$filespec"
echo


# Create the /etc/bind/logging-categories-named.conf
filename="$(basename "$INSTANCE_CATEGORY_NAMED_CONF_FILESPEC")"
filepath="$(dirname  "$INSTANCE_CATEGORY_NAMED_CONF_FILESPEC")"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$filespec ..."
cat << NAMED_CHANNEL_CONF | tee "${BUILDROOT}${CHROOT_DIR}/$filespec" > /dev/null
#
# File: ${filename}
# Path: ${filepath}
# Title: Provides logging category configuration for ISC Bind9 named daemon
#
# Description:
#   To be included by $INSTANCE_LOGGING_NAMED_CONF_FILESPEC file
#
# Generator: $(basename "$0")
# Created on: $(date)
#


	category default { default_channel; };
	category general { general_channel; };
	category database { database_channel; };
	category security { security_channel; };
	category config { config_channel; };
	category resolver { resolver_channel; };
	category xfer-in { xfer-in_channel; };
	category xfer-out { xfer-out_channel; };
	category notify { notify_channel; };
	category client { client_channel; };
	category unmatched { unmatched_channel; };
	category queries { queries_channel; };
	category query-errors { query-errors_channel; };
	category network { network_channel; };
	category update { update_channel; };
	category update-security { update-security_channel; };
	category dispatch { dispatch_channel; };
	category dnssec { dnssec_channel; };
	category lame-servers { lame-servers_channel; };
	category delegation-only { delegation-only_channel; };
	category rate-limit { rate-limit_channel; };

NAMED_CHANNEL_CONF
flex_chmod 0640 "$filespec"
flex_chown "root:$GROUP_NAME" "$filespec"
echo


if [ $UID -ne 0 ]; then
  echo "NOTE: Unable to perform syntax-checking this in here."
  echo "      named-checkconf needs CAP_SYS_CHROOT capability in non-root $USER"
  echo "      ISC Bind9 Issue #3119"
  echo "You can execute:"
  echo "  $named_checkconf_filespec -i -p -c -x $named_chroot_opt $INSTANCE_NAMED_CONF_FILESPEC"
  read -rp "Do you want to sudo the previous command? (Y/n): " -eiY
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
fi
if [ "$REPLY" != 'n' ]; then
  # Check syntax of named.conf file
  named_chroot_opt="-t ${BUILDROOT}${CHROOT_DIR}"

# shellcheck disable=SC2086
  sudo $named_checkconf_filespec -c \
    -i \
    -p \
    -x \
    $named_chroot_opt \
    "$INSTANCE_NAMED_CONF_FILESPEC"
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "File $INSTANCE_NAMED_CONF_FILESPEC did not pass syntax."
# shellcheck disable=SC2086
    sudo $named_checkconf_filespec -c \
      -i \
      -p \
      -x \
      $named_chroot_opt \
      "$INSTANCE_NAMED_CONF_FILESPEC"
    echo "File $INSTANCE_NAMED_CONF_FILESPEC did not pass syntax."
    exit $retsts
  fi
  if [ $retsts -ne 0 ]; then
    exit $retsts
  else
    echo "Syntax-check passed for ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_NAMED_CONF_FILESPEC"
  fi
fi
echo

if [ "${BUILDROOT:0:1}" == '/' ]; then
  echo "Restarting $SYSTEMD_NAMED_SERVICE service using 'systemctl restart'..."
  systemctl restart "$INSTANCE_SYSTEMD_NAMED_SERVICE"
  retsts=$?
  echo "Checking RNDC control connection ..."
  rndc -c "$INSTANCE_RNDC_CONF_FILESPEC" status
  retsts=$?
else
  echo "Execute the following:"
  echo "  systemctl restart $INSTANCE_SYSTEMD_NAMED_SERVICE"
  echo "  rndc -c $INSTANCE_RNDC_CONF_FILESPEC status"
fi
echo
  
echo "Done."

