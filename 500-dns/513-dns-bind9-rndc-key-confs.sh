#!/bin/bash
# File: 513-dns-bind9-rndc-confs.sh
# Title: Create rndc configuration file for Bind9
# Description:
#   Creates the rndc by systemd unit instance.
#   Generates the final-form 'rndc-<instance>.conf' in /etc/bind directory
#   Generates the interim-form 'named-controls.conf' in
#       build/partial-configs/<instance>/ directory
#
#   Hash MAC is SHA512 (configurable at KEY_ALGORITHM)
#
#   rndc keys are stored in their respective instance subdirectory.
#   Default rndc key is stored in /var/lib/bind/keys
#   Default rndc keyname are in rndc-sha512.key format
#   All instance-specific rndc keys are stored in /var/lib/bind/<instance>/keys
#   All instance-specific rndc keyname are in rndc-<instance>-sha512.key format
#
#   All rndc control clauses are located in /etc/bind directory
#   rndc control clause by default is in /etc/bind/rndc.conf
#   rndc-control clause by instance is /etc/bind/rndc-<instance>.conf
#
# Environment Variables:
#   - RNDC_PORT - Port number for Remote Name Daemon Control (rndc)
#   - RNDC_CONF - rndc configuration filespec
#   - INSTANCE_NAME - Bind9 instance name, if any
#   - KEY_ALGORITHM - hmac-sha512, hmac-sha384, hmac-sha256,
#                     hmac-sha224, hmac-sha1, hmac-md5
#

source ./maintainer-dns-isc.sh

function create_rndc_conf_header() {
    echo "Creating ${CHROOT_DIR}$CORE_RNDC_CONF_FILESPEC ..."
    flex_touch "$CORE_RNDC_CONF_FILESPEC"
    cat << EOF | tee "${BUILDROOT}${CHROOT_DIR}$CORE_RNDC_CONF_FILESPEC" >/dev/null
#
# File: ${CORE_RNDC_CONF_FILENAME}
# Path: ${CORE_RNDC_CONF_DIRSPEC}
# Title: config file for Remote Named Daemon Controller (rndc)
# Description:
#   Includes other instances of named servers to support
#   '-s' option in 'rndc' CLI.
#
#   Usage is 'rndc -s <instance-name> status'
#
# Creator: $(basename "$0")
# Date: $(date)
#

EOF
}

function append_to_rndc_conf() {
  write_line "${BUILDROOT}${CHROOT_DIR}$CORE_RNDC_CONF_FILESPEC"  "$1"
}


flex_mkdir "$CORE_RNDC_CONF_DIRSPEC"
flex_chown root:bind "$CORE_RNDC_CONF_DIRSPEC"
flex_chmod 0750      "$CORE_RNDC_CONF_DIRSPEC"

# RNDC conf are stored at /etc/bind for all instances of bind9 service.
# RNDC conf filename is suffixed with '-<instance_name>'
#   such as '/etc/bind/rndc-public.conf' for 'public' instance.
# RNDC keys are stored at /var/lib/bind/keys for all instances of bind9 service.

echo "ls ${BUILDROOT}${CHROOT_DIR}$CORE_RNDC_CONF_FILESPEC"
ls ${BUILDROOT}${CHROOT_DIR}$CORE_RNDC_CONF_FILESPEC
# Write master 'rndc.conf' for all 'rndc-<instance>.conf'
if [ -f "${BUILDROOT}${CHROOT_DIR}$CORE_RNDC_CONF_FILESPEC" ]; then
  read -r \
    -e -iA \
    -p "File $CHROOT_DIR$CORE_RNDC_CONF_FILESPEC exists; append or re-write it? (A/r): "
  REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  if [ -n "$REPLY" ] && [ "$REPLY" == 'r' ]; then
    rm "${BUILDROOT}${CHROOT_DIR}$CORE_RNDC_CONF_FILESPEC"
    create_rndc_conf_header
  fi
else
  create_rndc_conf_header
fi
flex_chown root:bind "$CORE_RNDC_CONF_FILESPEC"
flex_chmod 0640      "$CORE_RNDC_CONF_FILESPEC"

# Add an 'include "/etc/bind/rndc-public.conf";' to /etc/bind/rndc.conf
# Craft an instance name of rndc-<instance>.conf

if [ "$RNDC_CONF_FILESPEC" != "$CORE_RNDC_CONF_FILESPEC" ]; then
  echo "Appending 'include $RNDC_CONF_FILESPEC;' into $CORE_RNDC_CONF_FILESPEC..."
  # Append an include statement to master rndc.conf
  FOUND="$(grep "include \"${RNDC_CONF_FILESPEC}\";" "$BUILDROOT$CORE_RNDC_CONF_FILESPEC")"
  if [ -z "$FOUND" ]; then
    # only one copy of include statement added
    append_to_rndc_conf " "
    append_to_rndc_conf "# Use with 'rndc -s ${INSTANCE_NAME} status' command."
    append_to_rndc_conf "include \"$RNDC_CONF_FILESPEC\";"
  fi
fi

# RNDC keys are stored at /var/lib/bind/keys for all instances of bind9 service.
# rndc key used to be /etc/bind/keys
# rndc key is now in /var/lib/bind/keys
#  - this way the 'bind' operator can change out keys

# KEY_NAME="${ISC_RNDC_CONF_FILEPART}${INSTANCE_SUFFIX}-${KEY_ALGORITHM}"

# /var/lib/bind/<instance>/keys/rndc-<instance>-sha512.key
# rndc keys are spread out in /var/lib/bind/'instance'/keys,
# whereas rndc-<instance>.conf are centralized in /etc/bind
# RNDC_KEY_DIRSPEC="${var_lib_bind_dirpath}${INSTANCE_DIRSPEC}/keys"
if [ ! -d "${BUILDROOT}${CHROOT_DIR}$RNDC_KEY_DIRSPEC" ]; then
  echo "Directory ${CHROOT_DIR}RNDC_KEY_DIRSPEC does not exist; creating..."
  flex_mkdir "$RNDC_KEY_DIRSPEC"
fi
flex_chown root:bind "$RNDC_KEY_DIRSPEC"
flex_chmod 0750      "$RNDC_KEY_DIRSPEC"

flex_touch "$RNDC_KEY_FILESPEC"
flex_chown root:bind "$RNDC_KEY_FILESPEC"
flex_chmod 0640      "$RNDC_KEY_FILESPEC"

# Create the /var/lib/bind/keys/rndc-<instance>-sha512.key
#   /var/lib/bind will be tightly restricted to named namespace
/usr/sbin/rndc-confgen -a \
    -A "$KEY_ALGORITHM" \
    -k "$KEY_NAME" \
    -c "${BUILDROOT}${CHROOT_DIR}$RNDC_KEY_FILESPEC"

if [ -z "$INSTANCE_NAME" ]; then
  INSTANCE_NAME="default"
fi

# do not use 'options' in 'rndc<-instance>.conf', just 'key' and 'server'
echo "Creating $RNDC_CONF_FILESPEC ..."
flex_touch "$RNDC_CONF_FILESPEC"
flex_chown root:bind "$RNDC_CONF_FILESPEC"
flex_chmod 0640      "$RNDC_CONF_FILESPEC"
cat << EOF | tee "${BUILDROOT}${CHROOT_DIR}$RNDC_CONF_FILESPEC" >/dev/null
#
# File: ${INST_RNDC_CONF_FILENAME}
# Path: ${INST_RNDC_CONF_DIRSPEC}
# Title: Instance '$INSTANCE_NAME' settings for Remote Named Daemon Controller (rndc)
# Creator: $(basename "$0")
# Date: $(date)
# Description:
#    '$INSTANCE_NAME' instance for 'rndc' using $KEY_ALGORITHM algorithm.
#
# Usage:
#    rndc -s $INSTANCE_NAME status
#
#
# To recreate the key for rndc, '$INSTANCE_NAME' instance, run:
#
#   /usr/sbin/rndc-confgen -a \\
#     -A $KEY_ALGORITHM \\
#     -k "$KEY_NAME" \\
#     -c "$RNDC_KEY_FILESPEC"

# common 'key' clause declarator
# this '$INSTANCE_NAME' key gets used here and in \$UNDEFINED_NAMED_CONF_INCLUDE
include "${RNDC_KEY_FILESPEC}";

# Used with 'rndc -s $INSTANCE_NAME status'
server ${INSTANCE_NAME} {
    key ${KEY_NAME};
    addresses {
        127.0.0.1 port ${RNDC_PORT};
        };
    };

EOF

# Write to the build/partial-configs/controls.conf for controls clause and its settings
if [ ! -d "${PARTCFG_CONTROLS_DIRSPEC}" ]; then
  mkdir "${PARTCFG_CONTROLS_DIRSPEC}" || exit 9
fi
cat << EOF | tee "$PARTCFG_CONTROLS_FILESPEC" >/dev/null

# Used with 'rndc -s $INSTANCE_NAME status'
controls {
    inet 127.0.0.1 port ${RNDC_PORT} allow {
        127.0.0.1/32;
        } keys {
            "${KEY_NAME}";
        };
    };

EOF

echo ""
# Write to the /tmp/named.conf/ for 'key' clause and its settings
if [ ! -d "${PARTCFG_KEY_CLAUSE_DIRSPEC}" ]; then
  mkdir "${PARTCFG_KEY_CLAUSE_DIRSPEC}" || exit 9
fi

# only one copy of 'include' clause added to
#   build/partial-configs/<instance>/key-<instance>.conf
echo "# Used with 'rndc -s $INSTANCE_NAME status'" > "$PARTCFG_KEY_CLAUSE_FILESPEC"
echo "include \"$RNDC_KEY_FILESPEC\";" >> "${PARTCFG_KEY_CLAUSE_FILESPEC}"

echo ""
echo "Done."
exit 0

