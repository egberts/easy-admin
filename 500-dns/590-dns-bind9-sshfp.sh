#!/bin/bash
# File: 590-dns-bind-sshfp.sh
# Title: Create a zone
# Description:
#
DEFAULT_ZONE_NAME="egbert.net"

echo "Create a zone database containing SSHFP records for ISC Bind9"
echo

source ./maintainer-dns-isc.sh

if [ "${BUILDROOT:0:1}" == '/' ]; then
  echo "Absolute build"
else
  readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-zones-named${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"
  mkdir -p "$BUILDROOT"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$ETC_DIRSPEC"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$VAR_DIRSPEC"
  mkdir -p "${BUILDROOT}${CHROOT_DIR}$VAR_LIB_DIRSPEC"
fi
echo
flex_mkdir "$ETC_NAMED_DIRSPEC"
flex_mkdir "$VAR_LIB_NAMED_DIRSPEC"
flex_mkdir "$INSTANCE_ETC_NAMED_DIRSPEC"
flex_mkdir "$INSTANCE_VAR_LIB_NAMED_DIRSPEC"


# Ask the user for the zone name (in form of a domain name)
if [ -n "$DEFAULT_ZONE_NAME" ]; then
  read_opt="-i${DEFAULT_ZONE_NAME}"
fi
read -rp "Enter in name of domain: " -e ${read_opt}
ZONE_NAME="$REPLY"
REQUESTED_DOMAIN_NAME="$REPLY"


# ZONE_NAME_LEN="${#REPLY}"
# if [ "${ZONE_NAME:${ZONE_NAME_LEN}}" != '.' ]; then
  # ZONE_NAME+='.'
# fi

echo "Primary (or Master)"
ZONE_TYPE_FILETYPE="pz"
ZONE_TYPE_NAME="primary"
ZONE_TYPE_NAME_C="Primary"


ZONE_CONF_FILENAME="${ZONE_TYPE_FILETYPE}.${ZONE_NAME}"

ZONE_CONF_DIRSPEC="${ETC_NAMED_DIRSPEC}"
ZONE_CONF_FILESPEC="${ETC_NAMED_DIRSPEC}/${ZONE_CONF_FILENAME}"
INSTANCE_ZONE_CONF_DIRSPEC="${INSTANCE_ETC_NAMED_DIRSPEC}"
flex_mkdir "$INSTANCE_ZONE_CONF_DIRSPEC"
INSTANCE_ZONE_CONF_FILESPEC="${INSTANCE_ZONE_CONF_DIRSPEC}/${ZONE_CONF_FILENAME}"

ZONE_DB_FILENAME="db.${ZONE_NAME}"

ZONE_DB_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}"
ZONE_DB_FILESPEC="${ZONE_DB_DIRSPEC}/${ZONE_DB_FILENAME}"

INSTANCE_ZONE_DB_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/${ZONE_TYPE_NAME}"
flex_mkdir "$INSTANCE_ZONE_DB_DIRSPEC"
INSTANCE_ZONE_DB_FILESPEC="${INSTANCE_ZONE_DB_DIRSPEC}/${ZONE_DB_FILENAME}"

INSTANCE_ZONE_KEYS_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/keys"

ZONE_DB_SSHFP_FILENAME="db.sshfp.${ZONE_NAME}"

ZONE_DB_SSHFP_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}"
ZONE_DB_SSHFP_FILESPEC="${ZONE_DB_SSHFP_DIRSPEC}/${ZONE_DB_SSHFP_FILENAME}"

INSTANCE_ZONE_DB_SSHFP_DIRSPEC="${INSTANCE_VAR_CACHE_NAMED_DIRSPEC}"
INSTANCE_ZONE_DB_SSHFP_FILESPEC="${INSTANCE_ZONE_DB_SSHFP_DIRSPEC}/$ZONE_DB_SSHFP_FILENAME"


# check that this host is different than the requested domain's name server
# - obtain this host info
THIS_HOSTNAME="$(hostname -f)"
THIS_DOMAIN="$(hostname -d)"

# - obtain requested domain's name server
SSHFP_DOMAIN_NS="$(dig +short $REQUESTED_DOMAIN_NAME SOA | awk '{print $1}')"
if [ "${SSHFP_DOMAIN_NS: -1}" != '.' ]; then
  SSHFP_DOMAIN_NS="${SSHFP_DOMAIN_NS:0:-1}"
fi
read -rp "Is this host a hidden-primary? (N/y): " -ein
REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
echo
if [ "$SSHFP_DOMAIN_NS" != "$THIS_HOSTNAME" ]; then
  if [ "$REPLY" == 'n' ]; then
    echo "ERROR: go to your hidden-primary host and re-run this script"
    echo "Aborted."
    exit 13
  fi
else
  if [ "$REPLY" != 'y' ]; then
    echo "This ($THIS_HOSTNAME) host is NOT the primary DNS server for"
    echo " your requested '$REQUESTED_DOMAIN_NAME' domain name."
    echo " go over to $SSHFP_DOMAIN_NS and re-run this script"
  else
    echo "Perform the following instruction over at $SSHFP_DOMAIN_NS host:"
    echo
    echo "   $ ssh <username>@$SSHFP_DOMAIN_NS"
    echo "   $ ssh-keygen -r $SSHFP_DOMAIN_NS > /tmp/db.${REQUESTED_DOMAIN_NAME}.sshfp"
    echo "   $ exit"
    echo "Then back on this $THIS_HOSTNAME host, execute:"
    echo "   $ sudo -i"
    echo "   $ cd ${INSTANCE_ZONE_DB_DIRSPEC}"
    echo "   $ scp <usernme>@${SSHFP_DOMAIN_NS}:/tmp/db.${REQUESTED_DOMAIN_NAME}.sshfp ."
    echo "   $ echo \"\$ORIGIN ${REQUESTED_DOMAIN_NAME}\" \\ "
    echo "         >> ${INSTANCE_ZONE_DB_DIRSPEC}/db.${REQUESTED_DOMAIN_NAME}"
    echo "   $ echo \"\$INCLUDE \"${INSTANCE_ZONE_DB_DIRSPEC}/db.${REQUESTED_DOMAIN_NAME}.sshfp\" \\ "
    echo "         >> ${INSTANCE_ZONE_DB_DIRSPEC}/db.${REQUESTED_DOMAIN_NAME}"
    echo "   $ exit"
    echo
    echo "Done."
  fi
  exit 13
fi

# Create the zone configuration extension file so other scripts
# can pile on more statements and its value settings

MASTER_DB_SSHFP="${INSTANCE_ZONE_DB_DIRSPEC}/db.sshfp.egbert.net"

echo "Creating ${BUILDROOT}${CHROOT_DIR}$MASTER_DB_SSHFP ..."
ssh-keygen -r "$SSHFP_DOMAIN_NS" > "${BUILDROOT}${CHROOT_DIR}$MASTER_DB_SSHFP"

flex_chown "root:$GROUP_NAME" "$MASTER_DB_SSHFP"
flex_chmod "0640"      "$MASTER_DB_SSHFP"
echo

echo "\$ORIGIN ${REQUESTED_DOMAIN_NAME}" >> ${BUILDROOT}${CHROOT_DIR}$INSTANCE_ZONE_DB_FILESPEC
echo "\$INCLUDE \"${MASTER_DB_SSHFP}\"" >> ${BUILDROOT}${CHROOT_DIR}$INSTANCE_ZONE_DB_FILESPEC

echo "Done."

