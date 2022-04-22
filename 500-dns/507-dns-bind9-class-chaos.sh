#!/bin/bash
# File: 507-dns-bind-class-chaos.sh
# Title: Set up the 'bind' zone in class CHAOS (as opposed to class IN)
#
# Basic user questioning:
#   There is only two sets of questions:
#     String contents:
#       What version string to use for 'bind.version'
#       What author string to use for 'bind.author'
#     These version/author are viewable by WHOM?  (TBD)
#       By-view  (TBD)
#       by-allowable-remote-IP subnets  (TBD)
#
# Files:
#   /var/lib/bind/db.ch.bind (create)
#   /etc/bind/mz.chaos.bind (create)
#   /etc/bind/views-named.conf (append)

# it is supposed to be 2AEF76E, but fudged here on purpose
DEFAULT_BIND_VERSION="Microsoft DNS 6.0.6100 (24EF76E)"
DEFAULT_BIND_AUTHOR="Microsoft"

echo "Set up CHAOS class for ISC Bind9"
echo

# 'bind.version' et. al. goes under /var/lib/bind[/intance]/db.ch.bind
DB_ZONE_BIND_CHAOS_CLASS_FILENAME="db.ch.bind"
ZONE_PRIMARY_BIND_FILENAME="pz.bind.ch"
VIEW_CHAOS_FILENAME="view.chaos.ch"

source ./maintainer-dns-isc.sh

INSTANCE_DB_ZONE_BIND_CHAOS_CLASS_FILESPEC="${INSTANCE_DB_PRIMARIES_DIRSPEC}/$DB_ZONE_BIND_CHAOS_CLASS_FILENAME"
INSTANCE_ZONE_PRIMARY_BIND_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/$ZONE_PRIMARY_BIND_FILENAME"
INSTANCE_VIEW_CHAOS_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/$VIEW_CHAOS_FILENAME"

# Are we making a build subdir or directly installing?
if [ "${BUILDROOT:0:1}" != '/' ]; then
  FILE_SETTING_PERFORM=false
  readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-class-chaos${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"
  rm -rf "$FILE_SETTINGS_FILESPEC"
  echo "Building $FILE_SETTINGS_FILESPEC script ..."
  mkdir -p "${BUILDROOT}${CHROOT_DIR}"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$ETC_DIRSPEC"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$VAR_DIRSPEC"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$VAR_LIB_DIRSPEC"
fi
if [[ -z "$BUILDROOT" ]] || [[ "$BUILDROOT" == '/' ]]; then
  # SUDO_BIN=sudo
  FILE_SETTING_PERFORM=true
  echo "Writing files as 'root'..."
else
  echo "Writing ALL files into $BUILDROOT as user '$USER')..."
fi
echo

flex_ckdir "$ETC_NAMED_DIRSPEC"
flex_ckdir "$VAR_LIB_NAMED_DIRSPEC"
flex_ckdir "$INSTANCE_ETC_NAMED_DIRSPEC"
flex_ckdir "$INSTANCE_VAR_LIB_NAMED_DIRSPEC"
flex_ckdir "$INSTANCE_DB_PRIMARIES_DIRSPEC"
flex_ckdir "$INSTANCE_DB_SECONDARIES_DIRSPEC"

#
#  User Interface Querying
#
read -rp "What string to use for 'bind.version'?: " -ei"$DEFAULT_BIND_VERSION"
BIND_VERSION="$REPLY"
read -rp "What string to use for 'bind.author'?: " -ei"$DEFAULT_BIND_AUTHOR"
BIND_AUTHOR="$REPLY"

#
# db.class.name file naming convention
#   /var/lib/bind/db.ch.bind (create)
filespec="${INSTANCE_DB_ZONE_BIND_CHAOS_CLASS_FILESPEC}"
filename="$(basename "$filespec")"
filepath="$(dirname "$filespec")"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << DB_CH_BIND_EOF | tee "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
;
; Zone: 'bind'
; File: $filename
; Path: $filepath
; Title: Resource Record database for the 'bind' zone, CHAOS class
; Generator: $(basename "$0")
; Created on: $(date)
;
\$TTL 3600
@   86400             SOA localhost. root.localhost. (
                      2013050803
                      3600
                      3600
                      1209600
                      86400 )

                      NS  localhost.

version     86400     TXT "${BIND_VERSION}"
authors     86400     TXT "${BIND_AUTHOR}"

DB_CH_BIND_EOF

flex_chown "${USER_NAME}:$GROUP_NAME" "$filespec"
flex_chmod 0640 "$filespec"
echo


# named zone configuration file for 'bind', CHAOS-class
#   /etc/bind[/instance]/pz.chaos.bind (create)
filespec="${INSTANCE_ZONE_PRIMARY_BIND_FILESPEC}"
filename="$(basename "$filespec")"
filepath="$(dirname "$filespec")"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << PZ_BIND_CH_EOF | tee "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
#
# Zone: 'bind'
# File: $filename
# Path: $filepath
# Title: Zone configuration for the 'bind' zone, CHAOS class
# Generator: $(basename "$0")
# Created on: $(date)
#
# To be included from within a view clause
# such as  ${INSTANCE_VIEW_NAMED_CONF_FILESPEC}
# or to be include as a zone clause such as:
#  ${INSTANCE_ZONE_NAMED_CONF_FILESPEC}
#
    zone "bind" CH {
        type master;

        // Where the zone database file is locate at
        file "${INSTANCE_DB_ZONE_BIND_CHAOS_CLASS_FILESPEC}";

        // this is a static resource record
        allow-update { none; };

        // this is a static resource record
        allow-transfer { none; };
        };

PZ_BIND_CH_EOF
flex_chown "${USER_NAME}:$GROUP_NAME" "$filespec"
flex_chmod 0640 "$filespec"
echo

#   append to /etc/bind/views-named.conf
filespec="${INSTANCE_VIEW_CHAOS_FILESPEC}"
filename="$(basename "$filespec")"
filepath="$(dirname "$filespec")"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << NOTIFY_OPTIONS_EOF | tee "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
#
# File: $filename
# Path: $filepath
# Title: Notify sub-options within 'options' clause
# Generator: $(basename "$0")
# Created on: $(date)
# Description:
#
#   All 'CH' class queries goes into this CHAOS view.
#
# To be included from within the ${VIEW_NAMED_CONF_FILENAME} config file
#
    view "chaos" CH {

        # We are only responsible for our own view
        recursion no;

        # anyone can ask for CHAOS-class RRs.
        match-clients { any; };

        # Zone data file containing all CHAOS-class resource records
include "${INSTANCE_ZONE_PRIMARY_BIND_FILESPEC}";

        };
NOTIFY_OPTIONS_EOF
flex_chown "${USER_NAME}:$GROUP_NAME" "$filespec"
flex_chmod 0640 "$filespec"
echo

#  Add CHAOS View
echo "include \"${INSTANCE_VIEW_CHAOS_FILESPEC}\";" \
    >> "${BUILDROOT}${CHROOT_DIR}$INSTANCE_VIEW_NAMED_CONF_FILESPEC"
echo "Done."

