#!/bin/bash
# File: 510-dns-bind9-reset-config.sh
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


BUILDROOT="${BUILDROOT:-build/}"

FILE_SETTINGS_FILESPEC="$BUILDROOT/file-settings-named.conf"
source maintainer-dns-isc.sh


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
  mkdir -p "$BUILDROOT"  # no flex_mkdir, this is an intermediate-build tmp directory
  mkdir -p "${BUILDROOT}/etc"
  mkdir -p "${BUILDROOT}/var"
fi
# Create skeleton subdirectory
flex_mkdir "$sysconfdir"
flex_chown root:bind "$sysconfdir"
flex_chmod 0750      "$sysconfdir"

flex_mkdir "$extended_sysconfdir"
flex_chown root:bind "$extended_sysconfdir"
flex_chmod 0750      "$extended_sysconfdir"

flex_mkdir "$ETC_SYSTEMD_DIRSPEC"
flex_chown root:bind "$ETC_SYSTEMD_DIRSPEC"
flex_chmod 0750      "$ETC_SYSTEMD_DIRSPEC"

flex_mkdir "$ETC_SYSTEMD_SYSTEM_DIRSPEC"
flex_chown root:bind "$ETC_SYSTEMD_SYSTEM_DIRSPEC"
flex_chmod 0750      "$ETC_SYSTEMD_SYSTEM_DIRSPEC"

flex_mkdir "$DEFAULT_LIB_DIRSPEC"
flex_chown root:bind "$DEFAULT_LIB_DIRSPEC"
flex_chmod 0750      "$DEFAULT_LIB_DIRSPEC"

flex_mkdir "$VAR_LIB_NAMED_DIRSPEC"
flex_chown root:bind "$VAR_LIB_NAMED_DIRSPEC"
flex_chmod 0750      "$VAR_LIB_NAMED_DIRSPEC"

flex_mkdir "$INSTANCE_DYNAMIC_DIRSPEC"
flex_chown root:bind "$INSTANCE_DYNAMIC_DIRSPEC"
flex_chmod 0750      "$INSTANCE_DYNAMIC_DIRSPEC"

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
# Generator: $(basename $0)
# Created on: $(date)
#

include "${INSTANCE_ACL_NAMED_CONF_FILESPEC}";
include "${INSTANCE_CONTROLS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_OPTIONS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_OPTIONS_BASTION_NAMED_CONF_FILESPEC}";
include "${INSTANCE_LOGGING_NAMED_CONF_FILESPEC}";
include "${INSTANCE_MANAGED_KEYS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_MASTERS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_SERVER_NAMED_CONF_FILESPEC}";
include "${INSTANCE_STATS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_TRUST_ANCHORS_NAMED_CONF_FILESPEC}";
include "${INSTANCE_VIEW_NAMED_CONF_FILESPEC}";
include "${INSTANCE_ZONE_NAMED_CONF_FILESPEC}";
include "${INSTANCE_KEY_NAMED_CONF_FILESPEC}";

NAMED_CONF_EOF
flex_chown "root:$GROUP_NAME" "$INSTANCE_NAMED_CONF_FILESPEC"
flex_chmod 0640      "$INSTANCE_NAMED_CONF_FILESPEC"


function create_header()
{
  FILESPEC=$1
  owner=$2
  perms=$3
  title=$4
  filename="$(basename $FILESPEC)"
  filepath="$(dirname $FILESPEC)"
  echo "Creating ${BUILDROOT}${CHROOT_DIR}$FILESPEC ..."
  cat << CH_EOF | tee "${BUILDROOT}${CHROOT_DIR}$FILESPEC" > /dev/null
#
# File: $filename
# Path: $filepath
# Title: $title
# Generator: $(basename $0)
# Created on: $(date)

CH_EOF
}


function append_include_clause()
{
  filespec="$1"
  include="$2"
  echo "Appending \"${include} into $filespec ..."
  echo "include \"${include}\";" >> "${BUILDROOT}${CHROOT_DIR}$filespec"
}

flex_mkdir "${INSTANCE_DYNAMIC_DIRSPEC}";
flex_mkdir "${INSTANCE_KEYS_DB_DIRSPEC}";

create_header "${INSTANCE_ACL_NAMED_CONF_FILESPEC}" root:bind 0640 "'acl' clauses"
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_CONTROLS_NAMED_CONF_FILESPEC"

create_header "$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC"
cat << OPTIONS_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC" > /dev/null
options {
	version "Funky DNS, eh?";
	directory "${INSTANCE_ETC_NAMED_DIRSPEC}";
	key-directory "${INSTANCE_KEYS_DB_DIRSPEC}";
	managed-keys-directory "${MANAGED_KEYS_DIRSPEC}";
	dump-file "${DUMP_CACHE_FILESPEC}";
	pid-file "${INSTANCE_RUN_DIRSPEC}/named.pid";
        statistics-file "${INSTANCE_STATS_NAMED_CONF_FILESPEC}";
        zone-statistics yes;
	allow-query { any; };
	recursion no;
	server-id none;
	transfer-format many-answers;
	notify no;
	max-transfer-time-in 60;
	allow-transfer { none; };

	allow-update {   # we edit zone file by using an editor, not 'rndc'
		none;
	};

	dnssec-accept-expired no;
	dnssec-validation yes;
	disable-algorithms "egbert.net." { 
		RSAMD5;		// 1
		DH;		// 2 - current standard
		DSA;		// DSA/SHA1
		4; 		// reserved
		RSASHA1;	// RSA/SHA-1
		6;		// DSA-NSEC3-SHA1
		7;		// RSASHA1-NSEC3-SHA1
		//		// RSASHA256;  // 8 - current standard
		9;		// reserved
		//		// RSASHA512;  // 10 - ideal standard
		11;		// reserved
		12;		// ECC-GOST; // GOST-R-34.10-2001
		//		// ECDSAP256SHA256; // 13 - best standard
		//		// ECDSAP384SHA384; // 14 - bestest standard
		//		// ED25519; // 15
		//		// ED448; // 16
		INDIRECT; 
		PRIVATEDNS; 
		PRIVATEOID; 
		255;
        	};

	//  Delegation Signer Digest Algorithms [DNSKEY-IANA] [RFC7344]
	//  https://tools.ietf.org/id/draft-ietf-dnsop-algorithm-update-01.html
	disable-ds-digests "egbert.net" {
		0;		// 0
		SHA-1;		// 1 - Must deprecate 
		//		// SHA-256; // Widespread use
		GOST;		// 3 - has been deprecated by RFC6986
		//		// SHA-384;  // 4 - Recommended
		};

	// disables the SHA-256 digest for .net TLD only.
	disable-ds-digests "net" { "SHA-256"; };  // TBS: temporary

	max-rsa-exponent-size 4096;

	// conform to RFC1035
	auth-nxdomain no;

	session-keyfile "${SESSION_KEYFILE_DIRSPEC}/session.key";
	session-keyalg "hmac-sha256";
	session-keyname "${DHCP_TO_BIND_KEYNAME}";

	// RNDC ACL
	allow-new-zones no;

OPTIONS_EOF
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_OPTIONS_BASTION_NAMED_CONF_FILESPEC";
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_OPTIONS_LISTEN_ON_NAMED_CONF_FILESPEC";

append_include_clause \
  "$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC" \
  "$INSTANCE_OPTIONS_BASTION_NAMED_CONF_FILESPEC"

append_include_clause \
  "$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC" \
  "$INSTANCE_OPTIONS_LISTEN_ON_NAMED_CONF_FILESPEC"

cat << OPTIONS_EOF | tee -a "${BUILDROOT}${CHROOT_DIR}$INSTANCE_OPTIONS_NAMED_CONF_FILESPEC" > /dev/null
	};
OPTIONS_EOF



touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_OPTIONS_BASTION_NAMED_CONF_FILESPEC"
create_header "${INSTANCE_KEY_NAMED_CONF_FILESPEC}" root:bind 0640 "'key' clauses"
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_LOGGING_NAMED_CONF_FILESPEC"
create_header "${INSTANCE_MANAGED_KEYS_NAMED_CONF_FILESPEC}" root:bind 0640 "'managed-keys' clause"
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_MASTERS_NAMED_CONF_FILESPEC"
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_SERVER_NAMED_CONF_FILESPEC"
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_STATS_NAMED_CONF_FILESPEC"
touch "${BUILDROOT}${CHROOT_DIR}$INSTANCE_TRUST_ANCHORS_NAMED_CONF_FILESPEC"
create_header "${INSTANCE_VIEW_NAMED_CONF_FILESPEC}" root:bind 0640 "'view' clauses"
create_header "${INSTANCE_ZONE_NAMED_CONF_FILESPEC}" root:bind 0640 "'zone' clauses"

echo ""
echo "Done."
exit 0

