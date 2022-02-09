#!/bin/bash
# File: 551-dns-bind-zone-localhost.sh
# Title: Create a localhost zone
# Description:
#
DEFAULT_ZONE_NAME="localhost."

echo "Create a 'localhost' zone for ISC Bind9"
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

ZONE_NAME="localhost"

echo "Primary (or Master)"
ZONE_TYPE_FILETYPE="pz"
ZONE_TYPE_NAME="primary"
ZONE_TYPE_NAME_C="Primary"


ZONE_CONF_FILENAME="${ZONE_TYPE_FILETYPE}.${ZONE_NAME}"

ZONE_CONF_DIRSPEC="${ETC_NAMED_DIRSPEC}"
ZONE_CONF_FILESPEC="${ETC_NAMED_DIRSPEC}/${ZONE_CONF_FILENAME}"
INSTANCE_ZONE_CONF_DIRSPEC="${INSTANCE_ETC_NAMED_DIRSPEC}"
INSTANCE_ZONE_CONF_FILESPEC="${INSTANCE_ZONE_CONF_DIRSPEC}/${ZONE_CONF_FILENAME}"

ZONE_DB_FILENAME="db.${ZONE_NAME}"

ZONE_DB_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/${ZONE_TYPE_NAME}"
ZONE_DB_FILESPEC="${ZONE_DB_DIRSPEC}/${ZONE_DB_FILENAME}"

INSTANCE_ZONE_DB_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/${ZONE_TYPE_NAME}"
INSTANCE_ZONE_DB_FILESPEC="${INSTANCE_ZONE_DB_DIRSPEC}/${ZONE_DB_FILENAME}"

flex_mkdir "$INSTANCE_ZONE_DB_DIRSPEC"  # only create what we need

INSTANCE_ZONE_KEYS_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/keys"

ZONE_JOURNAL_FILENAME="${ZONE_NAME}-${ZONE_TYPE_NAME}.jnl"
INSTANCE_ZONE_JOURNAL_DIRSPEC="${INSTANCE_VAR_CACHE_NAMED_DIRSPEC}"
INSTANCE_ZONE_JOURNAL_FILESPEC="${INSTANCE_ZONE_JOURNAL_DIRSPEC}/$ZONE_JOURNAL_FILENAME"


# Create the zone configuration extension file so other scripts
# can pile on more statements and its value settings

# Create the Zone database for 'localhost'

filename="$(basename "$INSTANCE_ZONE_DB_FILESPEC")"
filepath="$(dirname "$INSTANCE_ZONE_DB_FILESPEC")"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << ZONE_DB_EOF | tee "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
;
; File: $filename
; Path: $filepath
; Title: ${ZONE_TYPE_NAME_C} Zone Configuration file for $ZONE_NAME domain.
; Generator: $(basename "$0")
; Created on: $(date)
;
;
; BIND data file for local loopback interface
;
$TTL	604800
$ORIGIN localhost.
@	IN	SOA	localhost. root.localhost. (
			9
			604800
			86400
			2419200
			604800 )
;
@	IN	NS	localhost.
@	IN	A	127.0.0.1
@	IN	AAAA	::1

ZONE_DB_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod 0640 "$filespec"


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

    allow-update { none; };
    forwarders { };
    notify no;

    auto-dnssec maintain;
    dnssec-load-interval 30;
    inline-signing yes;

};

ZONE_CONF_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod 0640 "$filespec"

echo "Done."

