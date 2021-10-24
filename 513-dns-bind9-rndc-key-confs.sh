#!/bin/bash
# File: 513-dns-bind9-rndc-conf.sh
# Title: Create rndc configuration file for Bind9
# Description:
#   Creates the rndc by systemd unit instance.
#
#   Hash MAC is SHA512 (configurable at KEY_ALGORITHM)
#
# /var/lib/bind/<instance>/keys/rndc-<instance>-sha512.key
# rndc keys are spread out in /var/lib/bind/'instance'/keys,
# whereas rndc-<instance>.conf are centralized in /etc/bind
#
# Prerequisites:
#   - RNDC_PORT - Port number for Remote Name Daemon Control (rndc)
#   - RNDC_CONF - rndc configuration filespec
#   - INSTANCE_NAME - Bind9 instance name, if any
#   - KEY_ALGORITHM - hmac-sha512, hmac-sha384, hmac-sha256,
#                     hmac-sha224, hmac-sha1, hmac-md5
#
KEY_ALGORITHM="${KEY_ALGORITHM:-hmac-sha512}"

sysconfdir="${sysconfdir:-/etc}"  # autotool default
localstatedir="${localstatedir:-/var/lib}"  # autotool default
RNDC_PORT="${RNDC_PORT:-953}"   # IANA-assigned number

# BIND_PKG_NAME="bind9"  # package name (not the same as package-specific directory name)
BIND_DIR_NAME="bind"  # directory name, as chosen by ISC

EXT_SYSCONF_DIRNAME="$BIND_DIR_NAME"
EXT_BIND_DIRPATH="${sysconfdir}/$EXT_SYSCONF_DIRNAME"
VAR_LIB_BIND_DIRPATH="${localstatedir}/bind"  # No, this isn't bind $HOME

INSTANCE_NAME="${INSTANCE_NAME:-}"
if [ -n "$INSTANCE_NAME" ]; then
  echo "Using $INSTANCE_NAME as the 'instance' name for systemd bind9 service"
  INSTANCE_SUFFIX="-${INSTANCE_NAME}"
  INSTANCE_DIRPATH="/${INSTANCE_NAME}"
else
  INSTANCE_SUFFIX=""
  INSTANCE_DIRPATH=""
fi
# TODO: Make it work for both 'rndc.conf' and 'rndc-public.conf', et. al.
RNDC_CONF_FILEPART="rndc"
RNDC_CONF_FILETYPE="conf"

# RNDC conf are stored at /etc/bind for all instances of bind9 service.
# RNDC conf filename is suffixed with '-<instance_name>'
#   such as '/etc/bind/rndc-public.conf' for 'public' instance.
# RNDC keys are stored at /var/lib/bind/keys for all instances of bind9 service.

# Write master 'rndc.conf' for all 'rndc-<instance>.conf'
MAIN_RNDC_CONF_FILENAME="${RNDC_CONF_FILEPART}.$RNDC_CONF_FILETYPE"
MAIN_RNDC_CONF_FILEPATH="$EXT_BIND_DIRPATH"
MAIN_RNDC_CONF_FILESPEC="${MAIN_RNDC_CONF_FILEPATH}/$MAIN_RNDC_CONF_FILENAME"
if [ -f "$MAIN_RNDC_CONF_FILESPEC" ]; then
  read -rp "File $MAIN_RNDC_CONF_FILESPEC exists; append or delete it? (A/d): " -eiA
  REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  if [ -n "$REPLY" ] && [ "$REPLY" == 'd' ]; then
    rm "$MAIN_RNDC_CONF_FILESPEC"
    echo "Creating $MAIN_RNDC_CONF_FILESPEC ..."
    sudo touch "$MAIN_RNDC_CONF_FILESPEC"
    cat << EOF | sudo tee "$MAIN_RNDC_CONF_FILESPEC" >/dev/null
#
# File: ${MAIN_RNDC_CONF_FILENAME}
# Path: ${MAIN_RNDC_CONF_FILEPATH}
# Title: config file for Remote Named Daemon Controller (rndc)
# Creator: $(basename "$0")
# Date: $(date)
#

EOF
  fi
  sudo chown root:bind "$MAIN_RNDC_CONF_FILESPEC"
  sudo chmod 0640      "$MAIN_RNDC_CONF_FILESPEC"
else
  echo "File $MAIN_RNDC_CONF_FILESPEC already exist; appending"
fi

# Add an 'include "/etc/bind/rndc-public.conf";' to /etc/bind/rndc.conf
# Craft an instance name of rndc-<instance>.conf
RNDC_CONF_FILENAME="${RNDC_CONF_FILEPART}${INSTANCE_SUFFIX}.$RNDC_CONF_FILETYPE"
# Store it in /etc/bind (despite availability of its instance subdirectory)
DEFAULT_RNDC_CONF="${EXT_BIND_DIRPATH}/$RNDC_CONF_FILENAME"
# Centralization of rndc*.conf files is the key (in 1 directory)
RNDC_CONF_FILESPEC="${RNDC_CONF:-$DEFAULT_RNDC_CONF}"  # ISC-default filespec
RNDC_CONF_FILENAME="$(basename "$RNDC_CONF_FILESPEC")"
RNDC_CONF_DIRPATH="$(dirname "$RNDC_CONF_FILESPEC")"

if [ "$RNDC_CONF_FILESPEC" != "$MAIN_RNDC_CONF_FILESPEC" ]; then
  echo "Appending 'include $RNDC_CONF_FILESPEC;' into $MAIN_RNDC_CONF_FILESPEC..."
  # Append an include statement to master rndc.conf
  FOUND="$(grep "include \"${RNDC_CONF_FILESPEC}\";" "$MAIN_RNDC_CONF_FILESPEC")"
  if [ -z "$FOUND" ]; then
    # only one copy of include statement added
    echo "include \"$RNDC_CONF_FILESPEC\";" | sudo tee -a "$MAIN_RNDC_CONF_FILESPEC" >/dev/null
  fi
fi

# RNDC keys are stored at /var/lib/bind/keys for all instances of bind9 service.
# rndc key used to be /etc/bind/keys
# rndc key is now in /var/lib/bind/keys
#  - this way the 'bind' operator can change out keys

KEY_NAME="${RNDC_CONF_FILEPART}${INSTANCE_SUFFIX}-${KEY_ALGORITHM}"

# /var/lib/bind/<instance>/keys/rndc-<instance>-sha512.key
# rndc keys are spread out in /var/lib/bind/'instance'/keys,
# whereas rndc-<instance>.conf are centralized in /etc/bind
RNDC_KEY_DIRPATH="${VAR_LIB_BIND_DIRPATH}${INSTANCE_DIRPATH}/keys"
if [ ! -d "$RNDC_KEY_DIRPATH" ]; then
  echo "Directory $RNDC_KEY_DIRPATH does not exist; creating..."
  sudo mkdir "$RNDC_KEY_DIRPATH"
fi
sudo chown root:bind "$RNDC_KEY_DIRPATH"
sudo chmod 0750      "$RNDC_KEY_DIRPATH"

RNDC_KEY_FILENAME="${KEY_NAME}.key"
RNDC_KEY_FILESPEC="${RNDC_KEY_DIRPATH}/$RNDC_KEY_FILENAME"
sudo touch "$RNDC_KEY_FILESPEC"
sudo chown root:bind "$RNDC_KEY_FILESPEC"
sudo chmod 0640      "$RNDC_KEY_FILESPEC"

# Create the /var/lib/bind/keys/rndc-<instance>-sha512.key
#   /var/lib/bind will be tightly restricted to named namespace
sudo /usr/sbin/rndc-confgen -a \
    -A "$KEY_ALGORITHM" \
    -k "$KEY_NAME" \
    -c "$RNDC_KEY_FILESPEC"

if [ -z "$INSTANCE_NAME" ]; then
  INSTANCE_NAME="default"
fi

# do not use 'options' in 'rndc<-instance>.conf', just 'key' and 'server'
echo "Creating $RNDC_CONF_FILESPEC ..."
sudo touch "$RNDC_CONF_FILESPEC"
sudo chown root:bind "$RNDC_CONF_FILESPEC"
sudo chmod 0640      "$RNDC_CONF_FILESPEC"
cat << EOF | sudo tee "$RNDC_CONF_FILESPEC" >/dev/null
#
# File: ${RNDC_CONF_FILENAME}
# Path: ${RNDC_CONF_DIRPATH}
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

# rndc 'key' clause declarator
include "${RNDC_KEY_FILESPEC}";

server ${INSTANCE_NAME} {
    key ${KEY_NAME};
    addresses {
        127.0.0.1 port ${RNDC_PORT};
        };
    };

EOF

# Write to the /tmp/named.conf/ for controls clause and its settings
CONTROLS_DIRPATH="/tmp/named.conf${INSTANCE_DIRPATH}"
CONTROLS_FILENAME="controls${INSTANCE_SUFFIX}-named.conf"
if [ ! -d "${CONTROLS_DIRPATH}" ]; then
  mkdir "${CONTROLS_DIRPATH}" || exit 9
fi
CONTROLS_FILESPEC="${CONTROLS_DIRPATH}/$CONTROLS_FILENAME"
cat << EOF | tee "$CONTROLS_FILESPEC"

# Used as 'rndc -s $INSTANCE_NAME status'
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
KEY_CLAUSE_DIRPATH="/tmp/named.conf${INSTANCE_DIRPATH}"
KEY_CLAUSE_FILENAME="key${INSTANCE_SUFFIX}-named.conf"
if [ ! -d "${KEY_CLAUSE_DIRPATH}" ]; then
  mkdir "${KEY_CLAUSE_DIRPATH}" || exit 9
fi
KEY_CLAUSE_FILESPEC="${KEY_CLAUSE_DIRPATH}/$KEY_CLAUSE_FILENAME"

# only one copy of include statement added
echo "# Used as 'rndc -s $INSTANCE_NAME status'" > "$KEY_CLAUSE_FILESPEC"
echo "include \"$RNDC_KEY_FILESPEC\";" >> "$KEY_CLAUSE_FILESPEC"

echo ""
echo "Done."
exit 0

