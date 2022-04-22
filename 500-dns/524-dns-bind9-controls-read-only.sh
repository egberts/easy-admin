#!/bin/bash
# File: 514-dns-bind-controls-read-only.sh
# Title: Configure a 'rndc' control access for READ-ONLY
#
# Description:
#
#   Appends to /etc/bind/named-controls.conf
#   Appends to /etc/bind/named-key.conf
#   Creates /etc/bind/controls-rndc-readonly-named.conf
#   Creates /etc/bind/rndc-readonly.conf but with 'read-only' attribute options
#   Creates /etc/bind/keys/rndc-readonly.key (RNDC_KEY_FILESPEC)
#
#   Restrict RNDC access of related files and netdev access
#   based on its intended usage.
#
#   This rndc only allows one role of a user; to read-only anything in named
#   over a designated named control channel (defaults to 127.0.0.1 port 953)
#

# Setting up instance-specific RNDC configuration and key files
HMAC_ALGORITHM="hmac-sha512"

# Used by 'named' and named.conf
KEY_READ_ONLY_NAMED_CONF_FILENAME="rndc-readonly.key"
CONTROLS_READ_ONLY_NAMED_CONF_FILENAME="controls-rndc-readonly-named.conf"

# Used by 'rndc'
RNDC_CONF_READ_ONLY_FILENAME="rndc-readonly.conf"

echo "Create an RNDC control channel with read-only privilege"
echo

source ./maintainer-dns-isc.sh

RNDC_KEYNAME="rndc-readonly-key"  # override default 'rndc-key'

INSTANCE_KEY_READ_ONLY_NAMED_CONF_FILESPEC="${INSTANCE_RNDC_KEY_DIRSPEC}/$KEY_READ_ONLY_NAMED_CONF_FILENAME"
INSTANCE_CONTROLS_READ_ONLY_NAMED_CONF_FILESPEC="${INSTANCE_RNDC_CONF_DIRSPEC}/$CONTROLS_READ_ONLY_NAMED_CONF_FILENAME"
INSTANCE_RNDC_CONF_READ_ONLY_FILESPEC="${INSTANCE_ETC_NAMED_DIRSPEC}/$RNDC_CONF_READ_ONLY_FILENAME"

if [ "${BUILDROOT:0:1}" == '/' ]; then
  FILE_SETTING_PERFORM=true
  # absolute (rootfs?)
  echo "Absolute build"
else
  FILE_SETTING_PERFORM=false
  mkdir -p build
  readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-rndc-read-only${INSTANCE_NAMED_CONF_FILEPART_SUFFIX}.sh"
  rm -f "$FILE_SETTINGS_FILESPEC"
  mkdir build/etc
fi

flex_ckdir "${ETC_NAMED_DIRSPEC}"
if [ -n "$INSTANCE" ]; then
  flex_ckdir "${INSTANCE_ETC_NAMED_DIRSPEC}"
fi
flex_ckdir "${INSTANCE_ETC_NAMED_DIRSPEC}/keys"

# Generate RNDC keys
# /etc/bind/key/rndc-readonly.key
echo "Generating RNDC key ..."
rndc-confgen -a \
    -c "${BUILDROOT}${CHROOT_DIR}$INSTANCE_KEY_READ_ONLY_NAMED_CONF_FILESPEC" \
    -k "$RNDC_KEYNAME" \
    -A "$HMAC_ALGORITHM"
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Error in rndc-congen: Errno $retsts"
  exit $retsts
fi
echo "Created ${BUILDROOT}${CHROOT_DIR}$INSTANCE_RNDC_KEY_FILESPEC"
flex_chmod 0640 "$INSTANCE_KEY_READ_ONLY_NAMED_CONF_FILESPEC"
flex_chown "${USER_NAME}:$GROUP_NAME" "$INSTANCE_KEY_READ_ONLY_NAMED_CONF_FILESPEC"
# Newly created 'rndc-readonly.key' can now be used by
# 'rndc-readonly.conf' and included into 'keys-named.conf'


# Create the /etc/bind/rndc-readonly.conf
filename="$(basename "$INSTANCE_RNDC_CONF_READ_ONLY_FILESPEC")"
filepath="$(dirname "$INSTANCE_RNDC_CONF_READ_ONLY_FILESPEC")"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}${filespec}"
cat << RNDC_MASTER_CONF | tee "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
#
# File: ${filename}
# Path: ${filepath}
# Title: RNDC configuration file for read-only access
# Read-only: TRUE
# Key name: $RNDC_KEYNAME
# IP interface: inet 127.0.0.2
# IP Port: 953
# Generator: $(basename "$0")
# Created on: $(date)
#
# To be used as:
#    rndc -c ${filename} status
#
options {
    default-key "${RNDC_KEYNAME}";
    default-server 127.0.0.2;
    default-port ${RNDC_PORT};
    };

# Always hide keys from main config file
include "${INSTANCE_KEY_READ_ONLY_NAMED_CONF_FILESPEC}";
RNDC_MASTER_CONF
flex_chmod 0640 "$filespec"
flex_chown "${USER_NAME}:$GROUP_NAME" "$filespec"
echo

# Create the /etc/bind/controls-read-only-named.conf
filename="$(basename "$INSTANCE_CONTROLS_READ_ONLY_NAMED_CONF_FILESPEC")"
filepath="$(dirname  "$INSTANCE_CONTROLS_READ_ONLY_NAMED_CONF_FILESPEC")"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << NAMED_KEY_CONF | tee "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
#
# File: ${filename}
# Path: ${filepath}
# Title: Provides a read-only control access to named daemon
# Read-only: TRUE
# IP interface: inet 127.0.0.2
# IP Port: 953
#
# Description:
#   To be included by $INSTANCE_CONTROLS_NAMED_CONF_FILESPEC file
#
# Generator: $(basename "$0")
# Created on: $(date)
#

controls {
    inet 127.0.0.2 port ${RNDC_PORT} allow {
        127.0.0.2/32;
            } keys {
            "${RNDC_KEYNAME}";
            } read-only true;
    };

NAMED_KEY_CONF

flex_chmod 0640 "$filespec"
flex_chown "${USER_NAME}:$GROUP_NAME" "$filespec"
echo

# Must check if file exist otherwise run named.conf init script
if [ ! -f "${BUILDROOT}${CHROOT_DIR}$INSTANCE_KEY_NAMED_CONF_FILESPEC" ]; then
  echo "File ${BUILDROOT}${CHROOT_DIR}$INSTANCE_KEY_NAMED_CONF_FILESPEC is missing; aborted."
  exit 9
fi

# Insert 'include rndc-readonly.key' into key-named.conf
filename="$KEY_NAMED_CONF_FILENAME"
filepath="$INSTANCE_ETC_NAMED_DIRSPEC"
filespec="${filepath}/$filename"
echo "Appending $KEY_NAME to ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << NAMED_KEY_CLAUSE_CONF | tee -a "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
# read-only RNDC control key
include "$INSTANCE_KEY_READ_ONLY_NAMED_CONF_FILESPEC";

NAMED_KEY_CLAUSE_CONF
flex_chmod 0640 "$filespec"
flex_chown "${USER_NAME}:$GROUP_NAME" "$filespec"
echo



# Insert 'include rndc-readonly.conf' into controls-named.conf
filename="$(basename "$INSTANCE_CONTROLS_NAMED_CONF_FILESPEC")"
filepath="$INSTANCE_ETC_NAMED_DIRSPEC"
filespec="${filepath}/$filename"
echo "Appending $KEY_NAME to ${BUILDROOT}${CHROOT_DIR}$filespec ..."
cat << NAMED_CONTROLS_CLAUSE_CONF | tee -a "${BUILDROOT}${CHROOT_DIR}$filespec" > /dev/null
# read-only RNDC control
include "$INSTANCE_CONTROLS_READ_ONLY_NAMED_CONF_FILESPEC";

NAMED_CONTROLS_CLAUSE_CONF
flex_chmod 0640 "$filespec"
flex_chown "${USER_NAME}:$GROUP_NAME" "$filespec"
echo
exit


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
  if [ -n "$CHROOT_DIR" ]; then
    # Check syntax of named.conf file
    named_chroot_opt="-t ${BUILDROOT}${CHROOT_DIR}"
    pushd . > /dev/null
    cd "${BUILDROOT}${CHROOT_DIR}" || exit 20
  fi

# shellcheck disable=SC2086
  sudo $named_checkconf_filespec -c \
    -i \
    -p \
    -x \
    "$named_chroot_opt" \
    "$INSTANCE_NAMED_CONF_FILESPEC" \
    >/dev/null
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "File $INSTANCE_NAMED_CONF_FILESPEC did not pass syntax."
# shellcheck disable=SC2086
    sudo $named_checkconf_filespec -c \
      -i \
      -p \
      -x \
      "$named_chroot_opt" \
      "$INSTANCE_NAMED_CONF_FILESPEC"
    echo "File $INSTANCE_NAMED_CONF_FILESPEC did not pass syntax."
    popd > /dev/null || exit 19
    exit $retsts
  fi
  popd > /dev/null || exit 18
  if [ $retsts -ne 0 ]; then
    exit $retsts
  else
    echo "Syntax-check passed for ${BUILDROOT}${CHROOT_DIR}$INSTANCE_NAMED_CONF_FILESPEC"
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

