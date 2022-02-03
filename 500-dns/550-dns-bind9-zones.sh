#!/bin/bash
# File: 550-dns-bind-zones.sh
# Title: Create a zone
# Description:
#
DEFAULT_ZONE_NAME="egbert.net"

echo "Create a zone in ISC Bind9"
echo

source ./maintainer-dns-isc.sh

if [ "${BUILDROOT:0:1}" == '/' ]; then
  echo "Absolute build"
else
  FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-zones-named.sh"
  mkdir -p "$BUILDROOT"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$ETC_DIRSPEC"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$VAR_DIRSPEC"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$VAR_LIB_DIRSPEC"
  flex_mkdir "$ETC_NAMED_DIRSPEC"
  flex_mkdir "$VAR_LIB_NAMED_DIRSPEC"
  flex_mkdir "$INSTANCE_ETC_NAMED_DIRSPEC"
  flex_mkdir "$INSTANCE_VAR_LIB_NAMED_DIRSPEC"
fi
echo

# Ask the user for the zone name (in form of a domain name)
if [ -n "$DEFAULT_ZONE_NAME" ]; then
  read_opt="-i${DEFAULT_ZONE_NAME}"
fi
read -rp "Enter in name of domain: " -e ${read_opt}
ZONE_NAME="$REPLY"
# ZONE_NAME_LEN="${#REPLY}"
# if [ "${ZONE_NAME:${ZONE_NAME_LEN}}" != '.' ]; then
  # ZONE_NAME+='.'
# fi

# Ask for the type of zone that this nameserver will perform on this domain
read -rp "Is this host a Primary or Secondary for $ZONE_NAME?: (P/s): "
REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
if [ "$REPLY" == 's' ]; then
  echo "Secondary (or Slave)"
  ZONE_TYPE_FILETYPE="sz"
  ZONE_TYPE_NAME="secondary"
  ZONE_TYPE_NAME_C="Secondary"
else
  echo "Primary (or Master)"
  ZONE_TYPE_FILETYPE="pz"
  ZONE_TYPE_NAME="primary"
  ZONE_TYPE_NAME_C="Primary"
fi


ZONE_CONF_FILENAME="${ZONE_TYPE_FILETYPE}.${ZONE_NAME}"
ZONE_CONF_EXTN_FILENAME="${ZONE_CONF_FILENAME}-zone-named.conf"

ZONE_CONF_DIRSPEC="${ETC_NAMED_DIRSPEC}"
ZONE_CONF_FILESPEC="${ETC_NAMED_DIRSPEC}/${ZONE_CONF_FILENAME}"
INSTANCE_ZONE_CONF_DIRSPEC="${INSTANCE_ETC_NAMED_DIRSPEC}"
INSTANCE_ZONE_CONF_FILESPEC="${INSTANCE_ZONE_CONF_DIRSPEC}/${ZONE_CONF_FILENAME}"
INSTANCE_ZONE_CONF_EXTN_FILESPEC="${INSTANCE_ZONE_CONF_DIRSPEC}/${ZONE_CONF_EXTN_FILENAME}"

ZONE_DB_FILENAME="db.${ZONE_NAME}"

ZONE_DB_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}"
ZONE_DB_FILESPEC="${ZONE_DB_DIRSPEC}/${ZONE_DB_FILENAME}"

INSTANCE_ZONE_DB_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/${ZONE_TYPE_NAME}"
INSTANCE_ZONE_DB_FILESPEC="${INSTANCE_ZONE_DB_DIRSPEC}/${ZONE_DB_FILENAME}"

INSTANCE_ZONE_KEYS_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/keys"

ZONE_JOURNAL_FILENAME="${ZONE_NAME}-${ZONE_TYPE_NAME}.jnl"
INSTANCE_ZONE_JOURNAL_DIRSPEC="${INSTANCE_VAR_CACHE_NAMED_DIRSPEC}"
INSTANCE_ZONE_JOURNAL_FILESPEC="${INSTANCE_ZONE_JOURNAL_DIRSPEC}/$ZONE_JOURNAL_FILENAME"


# Create the zone configuration extension file so other scripts
# can pile on more statements and its value settings

flex_touch "${INSTANCE_ZONE_CONF_EXTN_FILESPEC}";
flex_chown "root:$GROUP_NAME" "$INSTANCE_ZONE_CONF_EXTN_FILESPEC"
flex_chmod 0640 "$INSTANCE_ZONE_CONF_EXTN_FILESPEC"


# Create THE zone configuration file

filename="$(basename "$INSTANCE_ZONE_CONF_FILESPEC")"
filepath="$(dirname "$INSTANCE_ZONE_CONF_FILESPEC")"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << ZONE_CONF_EOF | tee "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
#
# File: $filename
# Path: $filepath
# Title: ${ZONE_TYPE_NAME_C} Zone Configuration file for $ZONE_NAME domain.
# Generator: $(basename "$0")
# Created on: $(date)
#
# Description:

zone "$ZONE_NAME" IN
{
    //// type 'master' is the server reads the zone data direct from
    //// local storage (a zone file) and provides authoritative
    //// answers for the zone.
    //
    type ${ZONE_TYPE_NAME};


    //// file statement defines the file used by the zone in 
    //// quoted string format, for instance, "secondary/example.com" - 
    //// or whatever convention you use. The file entry is 
    //// mandatory for 'primary' and 'hint' zone types and 
    //// optional - but highly recommended - for 'secondary' and 
    //// not required for forward zones. 
    ////
    //// The file may be an absolute path or relative to directory.
    //// But ISC Bind9 team highly recommend absolute path notation
    //// due to 'directory' statement being able to shift the
    //// current working directory under the daemon during reading
    //// of the named.conf file.  Some file-related statements
    //// may work before this 'directory' statement and the later 
    //// file-related will NOT work: and vice-versa.
    ////
    //// Note: If a type 'secondary' has a file statement then any zone 
    //// transfer will cause it to update this zone database file. 
    //// If the 'secondary' is reloaded then it will read this file 
    //// and immediately start answering queries for the domain. 
    //// If no file is specified it will immediately try to contact 
    //// the 'primary' and initiate a zone transfer. 
    //// For obvious reasons the 'secondary' cannot do zone queries 
    //// until this zone transfer gets completed. 
    //// If the 'primary' is not available or the 'secondary' 
    //// fails to contact the 'primary', for whatever reason, the 
    //// zone may be left with no effective Authoritative Name Servers.

    file "${INSTANCE_ZONE_DB_FILESPEC}";

    //// 'key-directory' is the directory where the public and 
    //// private DNSSEC key files should be found when 
    //// performing a dynamic update of secure zones, if 
    //// different than the current working directory. 
    ////
    //// Note that this option has no effect on the paths for 
    //// files containing non-DNSSEC keys such as bind.keys, 
    //// rndc.key, or session.key.

    key-directory "${INSTANCE_ZONE_KEYS_DIRSPEC}";


    //// 'journal' allows the default journal’s filename to 
    //// be overridden. The default is the zone’s filename 
    //// with “.jnl” appended. 
    //// This is applicable to primary and secondary zones.


    journal "${INSTANCE_ZONE_JOURNAL_FILESPEC}";

    //// If keys are present in the key directory the first 
    //// time the zone is loaded, the zone will be signed 
    //// immediately, without waiting for an rndc sign or 
    //// rndc loadkeys command. (Those commands can still be 
    //// used when there are unscheduled key changes, however.)
    //// 
    //// When new keys are added to a zone, the TTL is set to 
    //// match that of any existing DNSKEY RRset. If there is 
    //// no existing DNSKEY RRset, then the TTL will be set to 
    //// the TTL specified when the key was created (using the 
    //// dnssec-keygen -L option), if any, or to the SOA TTL.
    //// 
    //// If you wish the zone to be signed using NSEC3 instead 
    //// of NSEC, submit an NSEC3PARAM record via dynamic 
    //// update prior to the scheduled publication and 
    //// activation of the keys. If you wish the NSEC3 chain to 
    //// have the OPTOUT bit set, set it in the flags field of 
    //// the NSEC3PARAM record. The NSEC3PARAM record will not 
    //// appear in the zone immediately, but it will be stored 
    //// for later reference. When the zone is signed and the 
    //// NSEC3 chain is completed, the NSEC3PARAM record will 
    //// appear in the zone.
    //// 
    //// Using the auto-dnssec option requires the zone to be 
    //// configured to allow dynamic updates, by adding an 
    //// allow-update or update-policy statement to the zone 
    //// configuration. If this has not been done, the 
    //// configuration will fail.
    ////
    //// The "rndc loadkeys" command requires a "auto-dnssec maintain"
    //// statement in here.
    ////
    //// https://kb.isc.org/docs/aa-00626#
    ////

    auto-dnssec maintain;


    //// When a zone is configured with auto-dnssec maintain; 
    //// its key repository must be checked periodically to 
    //// see if any new keys have been added or any existing 
    //// keys’ timing metadata has been updated 
    //// (see dnssec-keygen: DNSSEC key generation tool and 
    //// dnssec-settime: set the key timing metadata for 
    //// a DNSSEC key). 
    ////
    //// The dnssec-loadkeys-interval option sets the 
    //// frequency of automatic repository checks, in minutes. 
    //// The default is 60 (1 hour), the minimum is 1 
    //// (1 minute), and the maximum is 1440 (24 hours); 
    //// any higher value is silently reduced.
    ////
    //// The 'rndc loadkeys' command forces named to check for
    //// key updates immediately.

    dnssec-load-interval 30;


    //// If 'inline-signing' is yes, this enables “bump in 
    //// the wire” signing of a zone, where a unsigned zone 
    //// is transferred in or loaded from disk and a 
    //// signed version of the zone is served with, 
    //// possibly, a different serial number. 
    ////
    //// This behavior is disabled by default.
    //
    // DO NOT use inline DNSSEC signing on a 'primary', 
    // only on a 'secondary'. 

    inline-signing yes;

// Allow for extensible settings
include "${INSTANCE_ZONE_CONF_EXTN_FILESPEC}";

///    // Some more stuff that needs to be done elsewhere
///    allow-query {
///        external_bastion_ip_acl;
///    };
///    update-policy local;
///
///    allow-transfer {  // for public
///        To only let 2 AML thru, use: !{ !{A; B;}; any; };
///        !{ !{trusted_downstream_nameservers_acl; localhost; }; any; };
///        key ddns-dhcpd-to-bind9-a;
///        key hidden-master-key;
///        !{ !localhost; any; };
///        key master-to-slave-key; // only localhost can use key
///        localhost; // not so useful for unsecured RNDC uses
///        none;
///        };
///    allow-transfer { trusted_residential_network_white_acl; }; // internal
///    forwarders {}; // internal-only
///    allow-update {  // internal-only
///        !{ !localhost; any; };
///        // only localhost got past this point here
///        // no one can update except localhost RNDC
///        key "rndc-key"; // only RNDC on localhost
///
///        //  'allow-update' on a "locally" view is essential for
///        //  communication between ISC-DHCP and BIND9
///        key "DDNS_UPDATER"; // only isc-dhcpd on localhost
///        // dnssec-policy leo_secured_domain; // available in Bind 9.15.8+
///    };



};

ZONE_CONF_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod 0640 "$filespec"

echo "Done."

