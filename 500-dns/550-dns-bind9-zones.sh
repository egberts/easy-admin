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

VIEW_CONF_FILEPART_SUFFIX="view."

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


### zone_conf_dirspec="${ETC_NAMED_DIRSPEC}" not needed
instance_zone_conf_dirspec="${INSTANCE_ETC_NAMED_DIRSPEC}"

view_conf_filesuffix="named.conf"


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
zone_types="pz mz sz ch hint"
for this_zone_type in $zone_types; do
  echo "Trying $this_zone_type zone type"
  this_zone_conf_filename="${zone_type_filetype}.${zone_name}"
  this_zone_conf_filespec="${instance_zone_conf_dirspec}/${this_zone_conf_filename}"
  find_type="$(find $instance_zone_conf_dirspec -name "${this_zone_type}.*" -print) | xargs"
  if [ -f "$this_zone_conf_filespec" ]; then
    echo "FOUND: $this_zone_conf_filespec file."
  fi

done
fi # false


# Ask the user for the zone name (in form of a fully-qualified domain name)
if [ -n "$DEFAULT_ZONE_NAME" ]; then
  read_opt="-i${DEFAULT_ZONE_NAME}"
fi
read -rp "Enter in domain name: " -e ${read_opt}
zone_name="$REPLY"
zone_name_len="${#REPLY}"
((zone_name_len--))
# crop the '.' off, if any
if [ "${zone_name:${zone_name_len}}" == '.' ]; then
  echo "Trimming extraneous suffix period (.) symbol ..."
  zone_name="${zone_name:0:-1}"
fi
fq_domain_name="${zone_name}."

zone_db_filename="db.${zone_name}"

# Ask for the type of zone that this nameserver will perform on this domain
read -rp "Is this host a Primary or Secondary for $zone_name?: (P/s): "
REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
if [ "$REPLY" == 's' ]; then
  echo "Secondary (or Slave)"
  zone_type_filetype="sz"
  zone_type_name="secondary"
  zone_type_name_c="Secondary"
else
  echo "Primary (or Master)"
  zone_type_filetype="pz"
  zone_type_name="primary"
  zone_type_name_c="Primary"
fi


zone_conf_filename="${zone_type_filetype}.${zone_name}"
zone_conf_extn_filename="${zone_conf_filename}-extension.conf"

# Need to compile a list of defined views, if any.
#  /etc/bind[/instance]/view-*-named.conf
views_filespec_a=($(find build/etc/bind -name "view.*-named.conf" ! -name "*-extension-named.conf"))
idx=0
prefix_len=${#VIEW_CONF_FILEPART_SUFFIX}
((++prefix_len))
views_a=()
for this_view_filespec in ${views_filespec_a[@]}; do
  temp="$(echo $(basename $this_view_filespec ) | cut -b ${prefix_len}- )"
  temp="$(echo $temp | sed -e "s/-named.conf//")"
  views_a[$idx]="$temp"
  ((++idx))
done

if [ "${#views_a[@]}" -le 0 ]; then
  echo "No view defined.  Go back and define a view."
  exit 7
fi
echo "Found the following view(s): ${views_a[*]}"
echo
PS3="ZONE $zone_name goes into which 'view'?: "
select view_name in ${views_a[@]} ; do
  retsts=$?
  echo "REPLY: $REPLY"
  echo "view_name: $view_name"
  echo "retsts: $retsts"
  if [ -z "$view_name" ]; then
    echo "Invalid input; select a digit"
    continue
  else
    break
  fi
# only way to exit silently is Ctrl-D (end-input)
done
if [ -z "$REPLY" -a -z "$view_name" ]; then
  view_name="${views_a[0]}"
fi
echo "view_name: $view_name"
view_conf_filepart="${VIEW_CONF_FILEPART_SUFFIX}$view_name"
view_conf_extn_filename="${view_conf_filepart}-extension-$view_conf_filesuffix"

### ZONE_CONF_FILESPEC="${ETC_NAMED_DIRSPEC}/${zone_conf_filename}" # not needed
instance_zone_conf_filespec="${instance_zone_conf_dirspec}/${zone_conf_filename}"
instance_zone_conf_extn_filespec="${instance_zone_conf_dirspec}/${zone_conf_extn_filename}"

zone_db_dirspec="${VAR_LIB_NAMED_DIRSPEC}/${zone_type_name}"
flex_mkdir "$zone_db_dirspec"
zone_db_filespec="${zone_db_dirspec}/${zone_db_filename}"

instance_zone_db_dirspec="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/${zone_type_name}"
flex_mkdir "$instance_zone_db_dirspec"
instance_zone_db_filespec="${instance_zone_db_dirspec}/${zone_db_filename}"

instance_zone_keys_dirspec="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/${zone_type_name}/keys"
flex_mkdir "$instance_zone_keys_dirspec"

zone_journal_filename="${zone_name}-${zone_type_name}.jnl"
instance_zone_journal_dirspec="${INSTANCE_VAR_CACHE_NAMED_DIRSPEC}"
instance_zone_journal_filespec="${instance_zone_journal_dirspec}/$zone_journal_filename"

view_conf_filename="${view_conf_filepart}-$view_conf_filesuffix"
#### view_conf_dirspec="${ETC_NAMED_DIRSPEC}"  # not needed
#### view_conf_filespec="${ETC_NAMED_DIRSPEC}/${view_conf_filename}"  # not needed
instance_view_conf_dirspec="${INSTANCE_ETC_NAMED_DIRSPEC}"
instance_view_conf_filespec="${instance_view_conf_dirspec}/${view_conf_filename}"
instance_view_conf_extn_filespec="${instance_view_conf_dirspec}/${view_conf_extn_filename}"


echo "Creating ${BUILDROOT}${CHROOT_DIR}/$instance_zone_db_dirspec ..."
flex_mkdir "$instance_zone_db_dirspec"
flex_chown "root:$GROUP_NAME" "$instance_zone_db_dirspec"
flex_chmod 0750               "$instance_zone_db_dirspec"

#    journal "${instance_zone_journal_filespec}";
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$instance_zone_journal_dirspec ..."
flex_mkdir "$instance_zone_journal_dirspec"
flex_chown "root:$GROUP_NAME" "$instance_zone_journal_dirspec"
flex_chmod 0750               "$instance_zone_journal_dirspec"

#    key-directory "${instance_zone_keys_dirspec}";
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$instance_zone_keys_dirspec ..."
flex_mkdir "${instance_zone_keys_dirspec}"
flex_chown "root:$GROUP_NAME" "$instance_zone_keys_dirspec"
flex_chmod 0750               "$instance_zone_keys_dirspec"

# include "${instance_zone_conf_extn_filespec}";
filespec="$instance_zone_conf_extn_filespec"
filename="$zone_conf_extn_filename"
filepath="$instance_zone_conf_dirspec"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$instance_zone_conf_extn_filespec ..."
cat << ZONE_EXTN_CONF_EOF | tee "${BUILDROOT}${CHROOT_DIR}/$instance_zone_conf_extn_filespec" > /dev/null
#
# File: ${filename}
# Path: ${filepath}
# Title: Extension to ${zone_type_name_c} '${zone_name}' zone clause config.
# Generator: $(basename "$0")
# Date: $(date)
#
# This file gets included in by ${zone_type_name} zone clause file
# for the '${zone_name}' zone:
#    '${instance_zone_conf_filespec}'
#

ZONE_EXTN_CONF_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod 0640               "$filespec"

#    file "${instance_zone_db_filespec}";
filespec="$instance_zone_db_filespec"
filename="$zone_db_filename"
filepath="$instance_zone_db_dirspec"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$instance_zone_db_filespec ..."
#
#  need name servers' IP, RI and hostname to flesh this database file out
#  so leave it just header-only
#
cat << ZONE_EXTN_DB_EOF | tee "${BUILDROOT}${CHROOT_DIR}/$instance_zone_db_filespec" > /dev/null
\$ORIGIN ${fq_domain_name}
; could use '$ORIGIN .' but we are being explicit here
; and would not support the accidential transferring of zone clause to other 
; disparate domain names.
;
; File: ${filename}
; Path: ${filepath}
; Title: ${zone_type_name_c} Zone database file for the '${zone_name}'
; Generator: $(basename "$0")
; Date: $(date)
;
; This file is referenced solely by the ${zone_type_name_c} '${zone_name}'
; zone clause configuration file: ${instance_zone_conf_filespec}
;

ZONE_EXTN_DB_EOF
flex_chown "root:$GROUP_NAME" "$filespec"
flex_chmod 0640 "$filespec"

# Lastly, create THE zone configuration file

filename="$zone_conf_filename"
filepath="$instance_zone_conf_dirspec"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << ZONE_CONF_EOF | tee "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
#
# File: $filename
# Path: $filepath
# Title: ${zone_type_name_c} Zone Configuration file for $zone_name domain.
# Generator: $(basename "$0")
# Created on: $(date)
#
# This file includes the accompanying extension file:
#    '${instance_zone_conf_extn_filespec}'
# This file gets included by the view clause configuration file:
#    '${instance_view_conf_extn_filespec}'
#
# Description:

zone "$zone_name" IN
{
    //// type 'primary' is the server reads the zone data direct from
    //// local storage (a zone file) and provides authoritative
    //// answers for the zone.
    //
    type ${zone_type_name};


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

    file "${instance_zone_db_filespec}";


    //// 'key-directory' is the directory where the public and
    //// private DNSSEC key files should be found when
    //// performing a dynamic update of secure zones, if
    //// different than the current working directory.
    ////
    //// Note that this option has no effect on the paths for
    //// files containing non-DNSSEC keys such as bind.keys,
    //// rndc.key, or session.key.

    key-directory "${instance_zone_keys_dirspec}";


    //// 'journal' allows the default journal’s filename to
    //// be overridden. The default is the zone’s filename
    //// with “.jnl” appended.
    //// This is applicable to primary and secondary zones.

    journal "${instance_zone_journal_filespec}";


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
    // only on a 'secondary'.  This is only true
    // for older Bind 9.6 or older

    inline-signing yes;


// Allow for extensible settings
include "${instance_zone_conf_extn_filespec}";


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
# Now insert the zone into a 'view' using $view_name

echo "$instance_view_conf_extn_filespec"
inc_pragma="include \"$filespec\";"
echo "Appending $inc_pragma into ${BUILDROOT}${CHROOT_DIR}/$instance_view_conf_extn_filespec"
echo "$inc_pragma" >> "${BUILDROOT}${CHROOT_DIR}/$instance_view_conf_extn_filespec"

echo "Done."
