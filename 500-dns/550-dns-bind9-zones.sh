#!/bin/bash
# File: 550-dns-bind-zones.sh
# Title: Create the zone's database
# Description:
#
#    Creates the default zone settings for a specified zone
#    into a zone-clause-specific configuration file.
#
#    Creates the extension file for zone clause of a specified zone.
#    This extension file contains user-specific and 
#    security-centric customizations.
#
#    Determine which view does this zone belongs to.
#      TBS: Do we create and nest by a view subdirectory or not (not for now)
#        - It would only hold a tiny number of zones (enterprise-y?)
#          - Hard to re-do directory tree if large number of zones (PRO)
#          - zone file names are already segregated by zone type (CON)
#
#    This script overwrites any pre-existing file of the specified 
#    zone name (that it may find) along with its corresponding 
#    zone-specific extension file (that it may find); but leaves 
#    its specified accompanied zone database file alone (does 
#    not overwrite zone databases).
#
#    If no corresponding zone database file is found, an empty
#    zone database file gets created in an empty zone but with 
#    a commented header file detailing which config file includes 
#    this zone database file (for ease-of-admin).
#
#    We have a separate script for working with its zone database file.
#
DEFAULT_ZONE_NAME="example.test"

echo "Create a zone configuration file for ISC Bind9"
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
  flex_mkdir "$VAR_CACHE_DIRSPEC"
  echo "Creating ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_ETC_NAMED_DIRSPEC ..."
  flex_mkdir "$INSTANCE_ETC_NAMED_DIRSPEC"
  echo "Creating ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_VAR_LIB_NAMED_DIRSPEC ..."
  flex_mkdir "$INSTANCE_VAR_LIB_NAMED_DIRSPEC"
  echo "Creating ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_VAR_CACHE_NAMED_DIRSPEC ..."
  flex_mkdir "$INSTANCE_VAR_CACHE_NAMED_DIRSPEC"
fi
echo


ZONE_CONF_DIRSPEC="${ETC_NAMED_DIRSPEC}"
INSTANCE_ZONE_CONF_DIRSPEC="${INSTANCE_ETC_NAMED_DIRSPEC}"

VIEW_CONF_FILESUFFIX="named.conf"


# Wait, try and find all available views to choose from
#
# By CLI cookie, detect WANTS_VIEW flag wanted or not (early user settings)
#  - View is an important DNS security feature, 
#    - probably should prompt for negative need of WANTS_VIEW flag, ONCE.
#      - Ask only during initialization?
#        -  Defaults to mandatory 'view' usage if no CLI cookie elsewhere
#    - implement WANTS_VIEW flag LASTLY near I&T
#    - TBD: identified mechanism between NEEDS_VIEW and WANTS_VIEW
#
# By view, find zones by 'include' statements within views-extension-named.conf
#   - may break by views/options misconfiguration (result: find no zone)
# By view, find zones by 'pz.zone-name' file name pattern
# By view, find zones by a valid named-checkconf doing the find via syntax check
#    - looks very attractive
#    - may break by views/options misconfiguration (result: find no zone)
#
# By zone, views automatically determined from 'include' in 'views-named.conf'
#
# Also, do we try to leverage 'named-checkconf -z' to get the list of zones?
#   using named-checkconf requires a valid working 'named.conf'
#   this tool will break if 'named.conf et. al.' is not 'correct' syntax-wise
#   makes 'inclusion' of new zone a bit harder
# or do we try script cookie-cutter 'Xz.xxxxx.domain.tld' file format?
#   script would controls who gets included into 'zones-named.conf' list file.
#   and user would controls which zone goes into which (pre-user-defined) view.
# or do we locate files having 'zone' name pattern and go with that?
#   past evocation of this script might pick up some lingering past zones
#   no longer included by main 'named.conf' or 'zones-named.conf'
# or try all of above, then 'sort -u' the zone names?
#
# 
if [ 0 -ne 0 ]; then
ZONE_TYPES="pz mz sz ch hint"
for this_zone_type in $ZONE_TYPES; do
  echo "Trying $this_zone_type zone type"
  THIS_ZONE_CONF_FILENAME="${ZONE_TYPE_FILETYPE}.${ZONE_NAME}"
  THIS_ZONE_CONF_FILESPEC="${INSTANCE_ZONE_CONF_DIRSPEC}/${THIS_ZONE_CONF_FILENAME}"
  FIND_TYPE="$(find $INSTANCE_ZONE_CONF_DIRSPEC -name "${this_zone_type}.*" -print) | xargs"
  if [ -f "$THIS_ZONE_CONF_FILESPEC" ]; then
    echo "FOUND: $THIS_ZONE_CONF_FILESPEC file."
  fi

done
fi # false


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


VIEW_CONF_FILEPART_SUFFIX="view."

ZONE_CONF_FILENAME="${ZONE_TYPE_FILETYPE}.${ZONE_NAME}"
ZONE_CONF_EXTN_FILENAME="${ZONE_CONF_FILENAME}-extension.conf"

# Need to compile a list of defined views, if any.
#  /etc/bind[/instance]/view-*-named.conf
VIEWS_FILESPEC_A=($(find build/etc/bind -name "view.*-named.conf" ! -name "*-extension-named.conf"))
idx=0
prefix_len=${#VIEW_CONF_FILEPART_SUFFIX}
((++prefix_len))
VIEWS_A=()
for this_view_filespec in ${VIEWS_FILESPEC_A[@]}; do
  temp="$(echo $(basename $this_view_filespec ) | cut -b ${prefix_len}- )"
  temp="$(echo $temp | sed -e "s/-named.conf//")"
  VIEWS_A[$idx]="$temp"
  ((++idx))
done

if [ "${#VIEWS_A[@]}" -le 0 ]; then
  echo "No view defined.  Go back and define a view."
  exit 7
fi
echo "Found the following view(s): ${VIEWS_A[*]}"
echo
PS3="ZONE $ZONE_NAME goes into which 'view'?: "
select VIEW_NAME in ${VIEWS_A[@]} ; do
  retsts=$?
  echo "REPLY: $REPLY"
  echo "VIEW_NAME: $VIEW_NAME"
  echo "retsts: $retsts"
  if [ -z "$VIEW_NAME" ]; then
    echo "Invalid input; select a digit"
    continue
  else
    break
  fi
# only way to exit silently is Ctrl-D (end-input)
done
if [ -z "$REPLY" -a -z "$VIEW_NAME" ]; then
  VIEW_NAME="${VIEWS_A[0]}"
fi
echo "VIEW_NAME: $VIEW_NAME"
VIEW_CONF_FILEPART="${VIEW_CONF_FILEPART_SUFFIX}$VIEW_NAME"
VIEW_CONF_EXTN_FILENAME="${VIEW_CONF_FILEPART}-extension-$VIEW_CONF_FILESUFFIX"

ZONE_CONF_DIRSPEC="${ETC_NAMED_DIRSPEC}"
ZONE_CONF_FILESPEC="${ETC_NAMED_DIRSPEC}/${ZONE_CONF_FILENAME}"
INSTANCE_ZONE_CONF_DIRSPEC="${INSTANCE_ETC_NAMED_DIRSPEC}"
INSTANCE_ZONE_CONF_FILESPEC="${INSTANCE_ZONE_CONF_DIRSPEC}/${ZONE_CONF_FILENAME}"
INSTANCE_ZONE_CONF_EXTN_FILESPEC="${INSTANCE_ZONE_CONF_DIRSPEC}/${ZONE_CONF_EXTN_FILENAME}"

ZONE_DB_FILENAME="db.${ZONE_NAME}"

ZONE_DB_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}/${ZONE_TYPE_NAME}"
flex_mkdir "$ZONE_DB_DIRSPEC"
ZONE_DB_FILESPEC="${ZONE_DB_DIRSPEC}/${ZONE_DB_FILENAME}"

INSTANCE_ZONE_DB_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/${ZONE_TYPE_NAME}"
flex_mkdir "$INSTANCE_ZONE_DB_DIRSPEC"
INSTANCE_ZONE_DB_FILESPEC="${INSTANCE_ZONE_DB_DIRSPEC}/${ZONE_DB_FILENAME}"

INSTANCE_ZONE_KEYS_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/${ZONE_TYPE_NAME}/keys"
flex_mkdir "$INSTANCE_ZONE_KEYS_DIRSPEC"

ZONE_JOURNAL_FILENAME="${ZONE_NAME}-${ZONE_TYPE_NAME}.jnl"
INSTANCE_ZONE_JOURNAL_DIRSPEC="${INSTANCE_VAR_CACHE_NAMED_DIRSPEC}"
INSTANCE_ZONE_JOURNAL_FILESPEC="${INSTANCE_ZONE_JOURNAL_DIRSPEC}/$ZONE_JOURNAL_FILENAME"

VIEW_CONF_FILENAME="${VIEW_CONF_FILEPART}-$VIEW_CONF_FILESUFFIX"
VIEW_CONF_DIRSPEC="${ETC_NAMED_DIRSPEC}"
VIEW_CONF_FILESPEC="${ETC_NAMED_DIRSPEC}/${VIEW_CONF_FILENAME}"
INSTANCE_VIEW_CONF_DIRSPEC="${INSTANCE_ETC_NAMED_DIRSPEC}"
INSTANCE_VIEW_CONF_FILESPEC="${INSTANCE_VIEW_CONF_DIRSPEC}/${VIEW_CONF_FILENAME}"
INSTANCE_VIEW_CONF_EXTN_FILESPEC="${INSTANCE_VIEW_CONF_DIRSPEC}/${VIEW_CONF_EXTN_FILENAME}"


echo "Creating ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_ZONE_DB_DIRSPEC ..."
flex_mkdir "$INSTANCE_ZONE_DB_DIRSPEC"
flex_chown "root:$GROUP_NAME" "$INSTANCE_ZONE_DB_DIRSPEC"
flex_chmod 0750               "$INSTANCE_ZONE_DB_DIRSPEC"

#    journal "${INSTANCE_ZONE_JOURNAL_FILESPEC}";
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_ZONE_JOURNAL_DIRSPEC ..."
flex_mkdir "$INSTANCE_ZONE_JOURNAL_DIRSPEC"
flex_chown "root:$GROUP_NAME" "$INSTANCE_ZONE_JOURNAL_DIRSPEC"
flex_chmod 0750               "$INSTANCE_ZONE_JOURNAL_DIRSPEC"

#    key-directory "${INSTANCE_ZONE_KEYS_DIRSPEC}";
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_ZONE_KEYS_DIRSPEC ..."
flex_mkdir "${INSTANCE_ZONE_KEYS_DIRSPEC}"
flex_chown "root:$GROUP_NAME" "$INSTANCE_ZONE_KEYS_DIRSPEC"
flex_chmod 0750               "$INSTANCE_ZONE_KEYS_DIRSPEC"

# include "${INSTANCE_ZONE_CONF_EXTN_FILESPEC}";
filespec="$INSTANCE_ZONE_CONF_EXTN_FILESPEC"
filename="$ZONE_CONF_EXTN_FILENAME"
filepath="$INSTANCE_ZONE_CONF_DIRSPEC"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_ZONE_CONF_EXTN_FILESPEC ..."
cat << ZONE_EXTN_CONF_EOF | tee "${BUILDROOT}${CHROOT_DIR}/$INSTANCE_ZONE_CONF_EXTN_FILESPEC" > /dev/null
#
# File: ${filename}
# Path: ${filepath}
# Title: Extension to ${ZONE_TYPE_NAME_C} '${ZONE_NAME}' zone clause config.
# Generator: $(basename "$0")
# Date: $(date)
#
# This file gets included in by ${ZONE_TYPE_NAME} zone clause file
# for the '${ZONE_NAME}' zone:
#    '${INSTANCE_ZONE_CONF_FILESPEC}'
#

ZONE_EXTN_CONF_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod 0640               "$filespec"

#    file "${INSTANCE_ZONE_DB_FILESPEC}";
filespec="$INSTANCE_ZONE_DB_FILESPEC"
filename="$ZONE_DB_FILENAME"
filepath="$INSTANCE_ZONE_DB_DIRSPEC"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_ZONE_DB_FILESPEC ..."
cat << ZONE_EXTN_DB_EOF | tee "${BUILDROOT}${CHROOT_DIR}/$INSTANCE_ZONE_DB_FILESPEC" > /dev/null
#
# File: ${filename}
# Path: ${filepath}
# Title: ${ZONE_TYPE_NAME_C} Zone database file for the '${ZONE_NAME}'
# Generator: $(basename "$0")
# Date: $(date)
#
# This file is referenced solely by the ${ZONE_TYPE_NAME_C} '${ZONE_NAME}'
# zone clause configuration file: ${INSTANCE_ZONE_CONF_FILESPEC}
#

ZONE_EXTN_DB_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod 0640 "$filespec"

# Lastly, create THE zone configuration file

filename="$ZONE_CONF_FILENAME"
filepath="$INSTANCE_ZONE_CONF_DIRSPEC"
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
# This file includes the accompanying extension file:
#    '${INSTANCE_ZONE_CONF_EXTN_FILESPEC}'
# This file gets included by the view clause configuration file:
#    '${INSTANCE_VIEW_CONF_EXTN_FILESPEC}'
#
# Description:

zone "$ZONE_NAME" IN
{
    //// type 'primary' is the server reads the zone data direct from
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

    dnssec-loadkeys-interval 30;


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
///        key hidden-primary-key;
///        !{ !localhost; any; };
///        key primary-to-secondary-key; // only localhost can use key
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
echo

#
# Now insert the zone into a 'view' using $VIEW_NAME

echo "$INSTANCE_VIEW_CONF_EXTN_FILESPEC"
inc_pragma="include \"$filespec\";"
echo "Appending $inc_pragma into ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_VIEW_CONF_EXTN_FILESPEC"
echo "$inc_pragma" >> "${BUILDROOT}${CHROOT_DIR}/$INSTANCE_VIEW_CONF_EXTN_FILESPEC"

echo "Done."
