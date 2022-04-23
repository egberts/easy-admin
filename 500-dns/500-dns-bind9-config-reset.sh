#!/bin/bash
# File: 510-dns-bind9-config-new.sh
# Title:  Restart Bind9 configuration from scratch
# Description:
#   Builds out the basic framework of named.conf via include files
#
#   All within the /etc/bind[/instance] directory
#
#   /named.conf
#     + acl-named.conf
#       + acl-public-outward-dynamic-interface-named.conf (if dynamic public IP)
#       + acl-public-bastion-interior-interface-named.conf  (bastion-only)
#       + acl-internal-bastion-interior-interface-named.conf  (bastion-only)
#       + acl-internal-outward-interface-named.conf
#     + controls-named.conf
#     + options-named.conf
#       + options-public-facing-dynamic-interfaces-named.conf (if dynamic IP)
#       + options-bastion-named.conf
#     + key-clauses-named.conf
#       + key-primary-to-secondaries-transfer.conf
#       + key-primary-dynamic-ip-ddns-ddclient.conf
#       + key-hidden-master-to-public-master.conf
#     + logging-named.conf
#     + managed-keys-named.conf
#     + masters-named.conf
#     + server-clauses-named.conf
#     + statistics-channels-named.conf
#     + trust-anchors-named.conf
#     + view-clauses-named.conf
#       + view-zone-clauses-named.conf
#         + zone-example.invalid-named.conf
#         + zone-example.org-named.conf
#         + zone-example.net-named.conf
#     + zone-clauses-named.conf (if no view clause)
#       + zone-example.invalid-named.conf (if no view clause)
#       + zone-example.org-named.conf (if no view clause)
#       + zone-example.net-named.conf (if no view clause)
#
echo "Resetting build area to empty."
echo

BUILDROOT="${BUILDROOT:-build}"
echo "Purging $BUILDROOT ..."

FILE_SETTING_PERFORM=false
readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-settings-named${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.conf"

source ./maintainer-dns-isc.sh

echo "Clearing out prior settings in $BUILDROOT"

# Defensive mechanism from unexpected disk wipe
if [ -n "$BUILDROOT" ]; then
  if [ "${BUILDROOT:0:1}" == "/" ]; then
    echo "BUILDROOT should be empty or a relative directory; not absolute path"
    echo "Aborted."
    exit 9
  fi
fi

# Absolute path for build?
if [ "${BUILDROOT:0:1}" == '/' ]; then
  echo "BUILDROOT: $BUILDROOT"
else
  rm -rf "$BUILDROOT"
  mkdir -v "$BUILDROOT"  # no flex_mkdir, this is an intermediate-build tmp directory
  mkdir -v "${BUILDROOT}${CHROOT_DIR}/etc"
  mkdir -v "${BUILDROOT}${CHROOT_DIR}/etc/systemd"
  mkdir -v "${BUILDROOT}${CHROOT_DIR}/etc/systemd/system"
  mkdir -v "${BUILDROOT}${CHROOT_DIR}/var"
  mkdir -v "${BUILDROOT}${CHROOT_DIR}/var/cache"
  mkdir -v "${BUILDROOT}${CHROOT_DIR}$VAR_LIB_NAMED_DIRSPEC"
fi

flex_ckdir "$extended_sysconfdir"
flex_chown bind:bind "$extended_sysconfdir"
flex_chmod 0750      "$extended_sysconfdir"

flex_ckdir "$INSTANCE_ETC_NAMED_DIRSPEC"
flex_chown bind:bind "$INSTANCE_ETC_NAMED_DIRSPEC"
flex_chmod 0750      "$INSTANCE_ETC_NAMED_DIRSPEC"

# /var/lib/bind
flex_ckdir "$VAR_LIB_NAMED_DIRSPEC"
flex_chown bind:bind "$VAR_LIB_NAMED_DIRSPEC"
flex_chmod 0750      "$VAR_LIB_NAMED_DIRSPEC"

# /var/lib/bind/instance
flex_ckdir "$INSTANCE_VAR_LIB_NAMED_DIRSPEC"
flex_chown bind:bind "$INSTANCE_VAR_LIB_NAMED_DIRSPEC"
flex_chmod 0750      "$INSTANCE_VAR_LIB_NAMED_DIRSPEC"

# formerly masters/ subdirectory
# /var/lib/bind[/instance]/primaries
flex_ckdir "$INSTANCE_VAR_LIB_NAMED_PRIMARIES_DIRSPEC"
flex_chown bind:bind "$INSTANCE_VAR_LIB_NAMED_PRIMARIES_DIRSPEC"
flex_chmod 0750      "$INSTANCE_VAR_LIB_NAMED_PRIMARIES_DIRSPEC"

# /var/lib/bind[/instance]/secondaries
flex_ckdir "$INSTANCE_VAR_LIB_NAMED_SECONDARIES_DIRSPEC"
flex_chown bind:bind "$INSTANCE_VAR_LIB_NAMED_SECONDARIES_DIRSPEC"
flex_chmod 0750      "$INSTANCE_VAR_LIB_NAMED_SECONDARIES_DIRSPEC"

# /var/lib/bind[/instance]/dynamic
flex_ckdir "$INSTANCE_DYNAMIC_DIRSPEC"
flex_chown bind:bind "$INSTANCE_DYNAMIC_DIRSPEC"
flex_chmod 0750      "$INSTANCE_DYNAMIC_DIRSPEC"

flex_ckdir "${INSTANCE_KEYS_DB_DIRSPEC}";
flex_chown bind:bind "$INSTANCE_KEYS_DB_DIRSPEC"
flex_chmod 0750      "$INSTANCE_KEYS_DB_DIRSPEC"
# logrotate
# apparmor
# firewall?

echo "Creating ${BUILDROOT}${CHROOT_DIR}$INSTANCE_NAMED_CONF_FILESPEC ..."
cat << NAMED_CONF_EOF | tee "${BUILDROOT}${CHROOT_DIR}$INSTANCE_NAMED_CONF_FILESPEC" > /dev/null
#
# File: $(basename "$INSTANCE_NAMED_CONF_FILESPEC")
# Path: $(dirname "$INSTANCE_NAMED_CONF_FILESPEC")
# Title: Main named.conf configuration file for ISC Bind9 name server
# Instance: ${INSTANCE}
# Generator: $(basename "$0")
# Created on: $(date)
#

include "${INSTANCE_ACL_NAMED_CONF_FILESPEC}";
include "${INSTANCE_CONTROLS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_OPTIONS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_LOGGING_NAMED_CONF_FILESPEC}";
include "${INSTANCE_MANAGED_KEYS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_PRIMARY_NAMED_CONF_FILESPEC}";
include "${INSTANCE_SERVER_NAMED_CONF_FILESPEC}";
include "${INSTANCE_STATS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_TRUST_ANCHORS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_VIEW_NAMED_CONF_FILESPEC}";
include "${INSTANCE_ZONE_NAMED_CONF_FILESPEC}";
include "${INSTANCE_KEY_NAMED_CONF_FILESPEC}";

NAMED_CONF_EOF
flex_chown "${USER_NAME}:$GROUP_NAME" "$INSTANCE_NAMED_CONF_FILESPEC"
flex_chmod 0640 "$INSTANCE_NAMED_CONF_FILESPEC"


function append_include_clause()
{
  filespec="$1"
  include="$2"
  echo "Appending \"${include} into $filespec ..."
  echo "include \"${include}\";" >> "${BUILDROOT}${CHROOT_DIR}$filespec"
}

#flex_mkdir "${INSTANCE_DYNAMIC_DIRSPEC}";

create_header "${INSTANCE_ACL_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'acl' clauses"

touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_CONTROLS_NAMED_CONF_FILESPEC"

create_header "$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'options' clauses"

cat << OPTIONS_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC" > /dev/null
options {
    directory "${INSTANCE_ETC_NAMED_DIRSPEC}";
    pid-file "${INSTANCE_PID_FILESPEC}";

    version "Funky DNS, eh?";
    server-id none;

OPTIONS_EOF

touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_OPTIONS_LISTEN_ON_NAMED_CONF_FILESPEC"

cat << OPTIONS_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC" > /dev/null
    recursion no;
    interface-interval 120;

    managed-keys-directory "${MANAGED_KEYS_DIRSPEC}";
    dump-file "${DUMP_CACHE_FILESPEC}";

    max-rsa-exponent-size 4096;
    session-keyalg "hmac-sha256"; // could use hmac-sha512
    session-keyfile "${SESSION_KEYFILE_DIRSPEC}/session.key";
    session-keyname "${DHCP_TO_BIND_KEYNAME}";
    statistics-file "${INSTANCE_STATS_NAMED_CONF_FILESPEC}";

    // RNDC ACL
    allow-new-zones no;

    // conform to RFC1035
    auth-nxdomain no;

    disable-algorithms "egbert.net." {
        RSAMD5;     // 1
        DH;     // 2 - current standard
        DSA;        // DSA/SHA1
        4;      // reserved
        RSASHA1;    // RSA/SHA-1
        6;      // DSA-NSEC3-SHA1
        7;      // RSASHA1-NSEC3-SHA1
        //      // RSASHA256;  // 8 - current standard
        9;      // reserved
        //      // RSASHA512;  // 10 - ideal standard
        11;     // reserved
        12;     // ECC-GOST; // GOST-R-34.10-2001
        //      // ECDSAP256SHA256; // 13 - best standard
        //      // ECDSAP384SHA384; // 14 - bestest standard
        //      // ED25519; // 15
        //      // ED448; // 16
        INDIRECT;
        PRIVATEDNS;
        PRIVATEOID;
        255;
            };
    //  Delegation Signer Digest Algorithms [DNSKEY-IANA] [RFC7344]
    //  https://tools.ietf.org/id/draft-ietf-dnsop-algorithm-update-01.html
    disable-ds-digests "egbert.net" {
        0;      // 0
        SHA-1;      // 1 - Must deprecate
        //      // SHA-256; // Widespread use
        GOST;       // 3 - has been deprecated by RFC6986
        //      // SHA-384;  // 4 - Recommended
        };
    // disables the SHA-256 digest for .net TLD only.
    disable-ds-digests "net" { "SHA-256"; };  // TBS: temporary

    dnssec-accept-expired no;
    dnssec-validation yes;
    transfer-format many-answers;
    allow-query { none; };
    allow-transfer { none; };
    allow-update { none; };  # we edit zone file by using an editor, not 'rndc'
    allow-notify { none; };
    forwarders { };

    key-directory "${INSTANCE_KEYS_DB_DIRSPEC}";
    max-transfer-time-in 60;
    notify no;
    zone-statistics yes;

include "${INSTANCE_OPTIONS_EXT_NAMED_CONF_FILESPEC}";
    };
OPTIONS_EOF

create_header "${INSTANCE_OPTIONS_EXT_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "extensions to 'options' clauses"


if [ 0 -ne 0 ]; then
# TODO: MOVE THIS BLOCK TO A SEPARATE SCRIPT FILE
# TODO: Do 'listen-on' in a separate script file
# TODO: Do 'bastion' in a separate script file
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_OPTIONS_LISTEN_ON_NAMED_CONF_FILESPEC";
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_OPTIONS_BASTION_NAMED_CONF_FILESPEC"
append_include_clause \
  "$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC" \
  "$INSTANCE_OPTIONS_BASTION_NAMED_CONF_FILESPEC"

append_include_clause \
  "$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC" \
  "$INSTANCE_OPTIONS_LISTEN_ON_NAMED_CONF_FILESPEC"
# touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_OPTIONS_BASTION_NAMED_CONF_FILESPEC"
fi


# /etc/named/key-named.conf
create_header "${INSTANCE_KEY_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'key' clauses"

# /etc/named/logging-named.conf
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_LOGGING_NAMED_CONF_FILESPEC"

# /etc/named/logging-named.conf
create_header "${INSTANCE_MANAGED_KEYS_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'managed-keys' clause"

touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_PRIMARY_NAMED_CONF_FILESPEC"
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_SERVER_NAMED_CONF_FILESPEC"
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_STATS_NAMED_CONF_FILESPEC"
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_TRUST_ANCHORS_NAMED_CONF_FILESPEC"

# views-named.conf holds multiple views
create_header "${INSTANCE_VIEW_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'view' clauses"

create_header "${INSTANCE_ZONE_NAMED_CONF_FILESPEC}" \
    "${USER_NAME}:$GROUP_NAME" 0640 "'zone' clauses"

echo
echo "Done."

