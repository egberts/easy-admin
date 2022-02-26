#!/bin/bash
# File: 514-dns-bind-logging.sh
# Title: Configure a 'logging' channel access for ISC Bind9 named daemon
#
# Description:
#
#   Creates /etc/bind[/$INSTANCE]/logging-named.conf
#   Creates /etc/bind[/$INSTANCE]/logging-channels-named.conf
#   Creates /etc/bind[/$INSTANCE]/logging-categories-named.conf
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
  readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-logging-named${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"
  mkdir -p build/etc
  flex_mkdir "${ETC_NAMED_DIRSPEC}"
  mkdir -p build/var
  mkdir -p build/var/log
  flex_mkdir "${log_dir}"
  if [ -n "$INSTANCE" ]; then
    flex_mkdir "${INSTANCE_ETC_NAMED_DIRSPEC}"
    flex_mkdir "${INSTANCE_LOG_DIRSPEC}"
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
# Reference:
#
#  * [BIND Logging - some basic recommendations](https://kb.isc.org/docs/aa-01526)
#
logging {

include "${INSTANCE_CHANNEL_NAMED_CONF_FILESPEC}";
include "${INSTANCE_CATEGORY_NAMED_CONF_FILESPEC}";

};
RNDC_LOGGING_CONF
flex_chmod 0640 "$filespec"
flex_chown "root:$GROUP_NAME" "$filespec"
echo

log_default_filespec="${INSTANCE_LOG_DIRSPEC}/default.log"
flex_touch "$log_default_filespec"
flex_chmod 0640 "$log_default_filespec"
flex_chown "root:$GROUP_NAME" "$log_default_filespec"

log_authoritative_servers_filespec="${INSTANCE_LOG_DIRSPEC}/authoritative_servers.log"
flex_touch "$log_authoritative_servers_filespec"
flex_chmod 0640 "$log_authoritative_servers_filespec"
flex_chown "root:$GROUP_NAME" "$log_authoritative_servers_filespec"

log_dnssec_filespec="${INSTANCE_LOG_DIRSPEC}/dnssec.log"
flex_touch "$log_dnssec_filespec"
flex_chmod 0640 "$log_dnssec_filespec"
flex_chown "root:$GROUP_NAME" "$log_dnssec_filespec"
log_zone_transfers_filespec="${INSTANCE_LOG_DIRSPEC}/zone_transfers.log"
flex_touch "$log_zone_transfers_filespec"
flex_chmod 0640 "$log_zone_transfers_filespec"
flex_chown "root:$GROUP_NAME" "$log_zone_transfers_filespec"
log_ddns_filespec="${INSTANCE_LOG_DIRSPEC}/ddns.log"
flex_touch "$log_ddns_filespec"
flex_chmod 0640 "$log_ddns_filespec"
flex_chown "root:$GROUP_NAME" "$log_ddns_filespec"
log_client_security_filespec="${INSTANCE_LOG_DIRSPEC}/client_security.log"
flex_touch "$log_client_security_filespec"
flex_chmod 0640 "$log_client_security_filespec"
flex_chown "root:$GROUP_NAME" "$log_client_security_filespec"
log_rate_limiting_filespec="${INSTANCE_LOG_DIRSPEC}/rate_limiting.log"
flex_touch "$log_rate_limiting_filespec"
flex_chmod 0640 "$log_rate_limiting_filespec"
flex_chown "root:$GROUP_NAME" "$log_rate_limiting_filespec"
log_rpz_filespec="${INSTANCE_LOG_DIRSPEC}/rpz.log"
flex_touch "$log_rpz_filespec"
flex_chmod 0640 "$log_rpz_filespec"
flex_chown "root:$GROUP_NAME" "$log_rpz_filespec"
log_dnstap_filespec="${INSTANCE_LOG_DIRSPEC}/dnstap.log"
flex_touch "$log_dnstap_filespec"
flex_chmod 0640 "$log_dnstap_filespec"
flex_chown "root:$GROUP_NAME" "$log_dnstap_filespec"
log_queries_filespec="${INSTANCE_LOG_DIRSPEC}/queries.log"
flex_touch "$log_queries_filespec"
flex_chmod 0640 "$log_queries_filespec"
flex_chown "root:$GROUP_NAME" "$log_queries_filespec"
log_query_errors_filespec="${INSTANCE_LOG_DIRSPEC}/query-errors.log"
flex_touch "$log_query_errors_filespec"
flex_chmod 0640 "$log_query_errors_filespec"
flex_chown "root:$GROUP_NAME" "$log_query_errors_filespec"

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
# Description:
#
#   Configures the location, level and type of logging that
#   BIND performs.
#
#   Unless you are using syslog you need a logging
#   statement for BIND.
#
#   To be included by $INSTANCE_LOGGING_NAMED_CONF_FILESPEC file
#
# Generator: $(basename "$0")
# Created on: $(date)
#
    channel default_log {
        file "${log_default_filespec}"
            versions $LOG_BACKUP_CNT
            size $LOG_FILE_SIZE
            suffix timestamp;
        severity info;
        // severity debug 7;
        // severity dynamic;
        print-time iso8601;
        print-severity true;
        print-category true;
        };
    channel authoritative_servers_log {
        file "${log_authoritative_servers_filespec}"
            versions $LOG_BACKUP_CNT
            size $LOG_FILE_SIZE;
        severity info;
        // severity debug 9;
        // severity dynamic;
        print-time yes;
        print-severity true;
        print-category true;
        };
    channel dnssec_log {
        file "${log_dnssec_filespec}"
            versions $LOG_BACKUP_CNT
            size $LOG_FILE_SIZE;
        severity info;
        print-time yes;
        print-severity true;
        print-category true;
        };
    channel zone_transfers_log {
        file "${log_zone_transfers_filespec}"
            versions $LOG_BACKUP_CNT
            size $LOG_FILE_SIZE;
        severity info;
        // severity dynamic;
        // severity debug 9;
        print-time yes;
        print-severity true;
        print-category true;
        };
    channel ddns_log {
        file "${log_ddns_filespec}"
            versions $LOG_BACKUP_CNT
            size $LOG_FILE_SIZE;
        severity info;
        print-time yes;
        print-severity true;
        print-category true;
        };
    channel client_security_log {
        file "${log_client_security_filespec}"
            versions $LOG_BACKUP_CNT
            size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 9;
        print-time yes;
        print-severity true;
        print-category true;
        };
    channel rate_limiting_log {
        file "${log_rate_limiting_filespec}"
            versions $LOG_BACKUP_CNT
            size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 3;
        print-time yes;
        print-severity true;
        print-category true;
        };
    channel rpz_log {
        file "${log_rpz_filespec}"
            versions $LOG_BACKUP_CNT
            size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 6;
        print-time yes;
        print-severity true;
        print-category true;
        };
    channel dnstap_log {
        file "${log_dnstap_filespec}"
            versions $LOG_BACKUP_CNT
            size $LOG_FILE_SIZE;
        //severity dynamic;
        severity debug 3;
        print-time yes;
        print-severity true;
        print-category true;
        };
    channel audit_channel {
        file "${log_audit_filespec}"
            versions $LOG_BACKUP_CNT
            size $LOG_FILE_SIZE;
        severity dynamic;
        // severity debug 3;
        print-time yes;
        print-severity true;
        print-category true;
        };
//
// If you have the category ‘queries’ defined, and you don’t want query logging
// by default, make sure you add option ‘querylog no;’ - then you can toggle
// query logging on (and off again) using command ‘rndc querylog’
//
    channel queries_log {
        file "${log_queries_filespec}"
            versions 600
            size 20m;
        severity info;
        print-time yes;
        print-severity yes;
        print-category yes;
        };
//
// This channel is dynamic so that when the debug level is increased using
// rndc while the server is running, extra information will be logged about
// failing queries.  Other debug information for other categories will be
// sent to the channel default_debug (which is also dynamic), but without
// affecting the regular logging.
//
    channel query-errors_log {
        file "${log_query_errors_filespec}"
            versions 5
            size 20m;
        severity dynamic;
        print-time yes;
        print-severity yes;
        print-category yes;
        };
//
// This is the default syslog channel, defined here for clarity.  You don’t
// have to use it if you prefer to log to your own channels.
// It sends to syslog’s daemon facility, and sends only logged messages
// of priority info and higher.
// (The options to print time, category and severity are non-default.)
//
    channel default_syslog {
        syslog daemon;
        severity info;
        print-time yes;
        print-severity yes;
        print-category yes;
        };
//
// This is the default debug output channel, defined here for clarity.  You
// might want to redefine the output destination if it doesn’t fit with your
// local system administration plans for logging.  It is also a special
// channel that only produces output if the debug level is non-zero.
//
    channel default_debug {
        // Gets written into bind/named \$HOME
        file "named.run";
        severity dynamic;
        print-time yes;
        print-severity yes;
        print-category yes;
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
# Reference:
#
#  * [BIND Logging - some basic recommendations](https://kb.isc.org/docs/aa-01526)
#

//
// Log routine stuff to syslog and default log:
//
    category default { default_syslog; default_debug; default_log; };
    category config { default_syslog; default_debug; default_log; };
    category dispatch { default_syslog; default_debug; default_log; };
    category network { default_syslog; default_debug; default_log; };
    category general { default_syslog; default_debug; default_log; };
//
// From BIND 9.12 and newer, you can direct zone load logging to another
// channel with the new zoneload logging category.  If this would be useful
// then firstly, configure the new channel, and then edit the line below
// to direct the category there instead of to syslog and default log:
//
    category zoneload { default_syslog; default_debug; default_log; };
//
// Log messages relating to what we got back from authoritative servers during
// recursion (if lame-servers and edns-disabled are obscuring other messages
// they can be sent to their own channel or to null).  Sometimes these log
// messages will be useful to research why some domains don’t resolve or
// don’t resolve reliably
//
    category resolver { authoritative_servers_log; default_debug; };
    category cname { authoritative_servers_log; default_debug; };
    category delegation-only { authoritative_servers_log; default_debug; };
    category lame-servers { authoritative_servers_log; default_debug; };
    category edns-disabled { authoritative_servers_log; default_debug; };
//
// Log problems with DNSSEC:
//
    category dnssec { dnssec_log; default_debug; };
//
// Log together all messages relating to authoritative zone propagation
//
    category notify { zone_transfers_log; default_debug; };
    category xfer-in { zone_transfers_log; default_debug; };
    category xfer-out { zone_transfers_log; default_debug; };
//
// Log together all messages relating to dynamic updates to DNS zone data:
//
    category update{ ddns_log; default_debug; };
    category update-security { ddns_log; default_debug; };
//
// Log together all messages relating to client access and security.
// (There is an additional category ‘unmatched’ that is by default sent to
// null but which can be added here if you want more than the one-line
// summary that is logged for failures to match a view).
//
    category client{ client_security_log; default_debug; };
    category security { client_security_log; default_debug; };
//
// Log together all messages that are likely to be related to rate-limiting.
// This includes RRL (Response Rate Limiting) - usually deployed on authoritative
// servers and fetches-per-server|zone.  Note that it does not include
// logging of changes for clients-per-query (which are logged in category
// resolver).  Also note that there may on occasions be other log messages
// emitted by the database category that don’t relate to rate-limiting
// behaviour by named.
//
    category rate-limit { rate_limiting_log; default_debug; };
    category spill { rate_limiting_log; default_debug; };
    category database { rate_limiting_log; default_debug; };
//
// Log DNS-RPZ (Response Policy Zone) messages (if you are not using DNS-RPZ
// then you may want to comment out this category and associated channel)
//
    category rpz { rpz_log; default_debug; };
//
// Log messages relating to the "dnstap" DNS traffic capture system  (if you
// are not using dnstap, then you may want to comment out this category and
// associated channel).
//
    category dnstap { dnstap_log; default_debug; };
//
// If you are running a server (for example one of the Internet root
// nameservers) that is providing RFC 5011 trust anchor updates, then you
// may be interested in logging trust anchor telemetry reports that your
// server receives to analyze anchor propagation rates during a key rollover.
// If this would be useful then firstly, configure the new channel, and then
// un-comment and the line below to direct the category there instead of to
// syslog and default log:
//
//
    category trust-anchor-telemetry { default_syslog; default_debug; default_log; };
//
// If you have the category ‘queries’ defined, and you don’t want query logging
// by default, make sure you add option ‘querylog no;’ - then you can toggle
// query logging on (and off again) using command ‘rndc querylog’
//
    category queries { queries_log; };
//
// This logging category will only emit messages at debug levels of 1 or
// higher - it can be useful to troubleshoot problems where queries are
// resulting in a SERVFAIL response.
//
    category query-errors {query-errors_log; };

// Other categories (commented out) will fall to 'default'
//    nsid
//    serve-stale
//    unmatched
//    rrl
//    rpz-passthru

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

