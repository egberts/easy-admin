#!/bin/bash
# File: 591-dns-bind-openpgpkey.sh
# Title: Create an OPENPGPKEY resource record
# Description:
#
DEFAULT_ZONE_NAME="egbert.net"

echo "Create a zone database containing OPENPGPKEY records for ISC Bind9"
echo

source ./maintainer-dns-isc.sh

if [ "${BUILDROOT:0:1}" == '/' ]; then
  echo "Absolute build"
else
  FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-zones-named${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"
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

ZONE_DB_OPENPGPKEY_FILENAME="db.openpgp.${ZONE_NAME}"

ZONE_DB_OPENPGPKEY_DIRSPEC="${VAR_LIB_NAMED_DIRSPEC}"
ZONE_DB_OPENPGPKEY_FILESPEC="${ZONE_DB_OPENPGPKEY_DIRSPEC}/${ZONE_DB_OPENPGPKEY_FILENAME}"

INSTANCE_ZONE_DB_OPENPGPKEY_DIRSPEC="${INSTANCE_VAR_LIB_NAMED_DIRSPEC}/$ZONE_TYPE_NAME"
INSTANCE_ZONE_DB_OPENPGPKEY_FILESPEC="${INSTANCE_ZONE_DB_OPENPGPKEY_DIRSPEC}/$ZONE_DB_OPENPGPKEY_FILENAME"


# check that this host is different than the requested domain's name server
# - obtain this host info
THIS_HOSTNAME="$(hostname -f)"
THIS_DOMAIN="$(hostname -d)"

# Grab an email address to create OPENPGPKEY DNS records
read -rp "Enter email address: "
EMAIL_ADDR="$REPLY"
EMAIL_LOCALPART="$(echo "$EMAIL_ADDR"|awk -F@ '{print $1}')"

# Do sha1sum on localpart of email, cut the first 26-char in
EMAIL_SHA1SUM="$(echo -n $EMAIL_LOCALPART | sha256sum | awk '{print $1}')"

# - obtain requested domain's name server
OPENPGPKEY_DOMAIN_NS="$(dig +short $REQUESTED_DOMAIN_NAME SOA | awk '{print $1}')"

if [ "${OPENPGPKEY_DOMAIN_NS: -1}" != '.' ]; then
  OPENPGPKEY_DOMAIN_NS="${OPENPGPKEY_DOMAIN_NS:0:-1}"
fi


# Create the zone configuration extension file so other scripts
# can pile on more statements and its value settings


echo "Creating ${BUILDROOT}${CHROOT_DIR}$INSTANCE_ZONE_DB_OPENPGPKEY_FILESPEC ..."

gpg --export-options export-dane --export "$EMAIL_ADDR" \
    2>/tmp/opengpgkey.cmd \
    > "${BUILDROOT}${CHROOT_DIR}/$INSTANCE_ZONE_DB_OPENPGPKEY_FILESPEC"
retsts=$?
WARN_FOUND="$(grep -c -i "warning:" /tmp/opengpgkey.cmd)"
if [ $retsts -ne 0 ] || [ $WARN_FOUND -ne 0 ]; then
  echo "No PGP found for $EMAIL_ADDR"
  echo "Aborted."
  exit $retsts
fi

flex_chown "root:$GROUP_NAME" "$INSTANCE_ZONE_DB_OPENPGPKEY_FILESPEC"
flex_chmod "0640"      "$INSTANCE_ZONE_DB_OPENPGPKEY_FILESPEC"
echo 

echo "\$ORIGIN ${REQUESTED_DOMAIN_NAME}" >> ${BUILDROOT}${CHROOT_DIR}$INSTANCE_ZONE_DB_FILESPEC
echo "\$INCLUDE \"${INSTANCE_ZONE_DB_OPENPGPKEY_FILESPEC}\"" >> ${BUILDROOT}${CHROOT_DIR}$INSTANCE_ZONE_DB_FILESPEC

echo "Done."

