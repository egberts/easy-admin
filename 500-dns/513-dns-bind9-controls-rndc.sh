#!/bin/bash
# File: 513-dns-bind-rndc-restrict.sh
# Title: Configure 'rndc' security
#
# Description:
#
#   Creates /etc/bind/named-controls.conf
#   Creates /etc/bind/named-key.conf
#   Creates /etc/bind/rndc.conf (RNDC_CONF_FILESPEC)
#   Creates /etc/bind/keys/rndc.key (RNDC_KEY_FILESPEC)
#
#   Restrict RNDC access of related files and netdev access 
#   based on its intended usage.
#
#   Three roles of full-admin-privileged usage of 'rndc' tool:
# 
#     * system administrator
#     * power end-users using their own copy of an RNDC key
#     * auto-evoked by other daemons/scripts
# 
# NOTE: There is no partial-admin-capability much less the remote 'read-only' 
#   capability in ISC Bind named/rndc.  That is, there is no way 
#   to separate read/write behavior within current 
#   'rndc' design such that we can differentiate a system 
#   administrator from a 'read-only' end-user.  
#   End-user, if allowed, would have same 
#   sysadmin privilege over IP network to add/delete DNS records.
#
# However, a read-only capability can be done at the same 
# host by setting all *.conf and zone DB files to 
# world-read (and their supporting directories).
#
# NOTE: named.conf provides ways for end-user/sysadmin to 
#       separately update the:
#   * individual zone's data
#   * forwarder assignments
#
# CAVEATS:
#   * Cannot use the same /etc/bind/rndc.conf file for a different
#     (or instantiated) named process.
#     * Because multiple chroots would result in making support for 
#       multiple-key (via 'rndc -s server') approach in the 
#       rndc.conf option into an non-reality 
#       (non-useable/non-sharable).
#     * locking down a key file's file permission to a different 
#       user/group ID would render said key file to be unaccessible
#       by another daemon having a different user/group ID.
#     * Cannot use 'include' clause in `rndc.conf` because of aboves.
#       * As a result, 'include' clause utility has diminished somewhat a bit
#   * therefore an instantiated rndc.conf (and its corrresponding key)
#        must reside under and within its own instantiated subdirectory.
#
# Detailed Design:
#
# if just the system administrator(s) alone (no users)
#  For 'rndc' binary, drop file ownership to 'root:bind'
#  For 'rndc' binary, drop world file permissions to '---' (no read/execute)
#  For 'rndc' binary, ensure group file permissions is 'r-x' (read/execute)
#  For 'rndc.key', drop file ownership to 'root:bind'
#  For 'rndc.key', drop world file permissions '---' (no read/execute/write)
#  For 'rndc.key', ensure group file permissions is 'r--' (read)
#  introduce 'bind' group enforcement to each applicable system administrator 
#    by executing 'usermod -a -G bind <username>'
#
# if got power users to cater (QA auditor/Common-Criteria-enforcer)
#  For 'rndc' binary, ensure file ownership is 'root:root'
#  For 'rndc' binary, ensure world file permissions is 'r-x' (read/execute)
#  For 'rndc' binary, ensure group file permissions is 'r-x' (read/execute)
#  For 'rndc.key', drop file ownership to 'root:bind'
#  For 'rndc.key', drop world file permissions '---' (no read/execute/write)
#  For 'rndc.key', ensure group file permissions is 'r--' (read)
#  create a new 'rndc.key' and labeled for each end-user
#  insert 'new labeled rndc.key' into named.conf
#  do not give 'bind' supplemental group to end-user:
#     This keeps zone files ('bind' group) as untouchable
#     but daily operation of 'named' may be altered
#     NOTE: nasty thing is that 'rndc' still can add/delete 'A' records
#
# If auto-evoked by other daemons/scripts (ie. ddclient dynamic IP update)
#  For 'rndc' binary, ensure world file permissions to 'r-x' (read/execute)
#  For 'rndc.key', drop world file permissions '---' (no read/execute/write)
#  must duplicate /etc/bind/rndc.key into that daemons config directory
#    instruct that daemons/scripts to use 'rndc -k /etc/daemon/rndc.key' instead
#  drop /etc/daemon/rndc.key to 'root:daemon' 0640 permission
#
# SECURITY-RISK: Allow ANYONE/ANYTHING within ONLY this host to run 'rndc' 
#                binary (distro default)
#  For 'rndc' binary, ensure world file permissions to 'r-x' (read/execute)
#  For 'rndc.key', ensure file ownership to 'root:root'
#  For 'rndc.key', ensure world file permissions 'r--' (read)
#
echo "Configure RNDC control channel and its various security settings."
echo

source ./maintainer-dns-isc.sh

if [ "${BUILDROOT:0:1}" == '/' ]; then
  # absolute (rootfs?)
  echo "Absolute build"
else
  mkdir -p build
  FILE_SETTINGS_FILESPEC="${BUILDROOT}${CHROOT_DIR}/file-rndc-security.sh"
  mkdir -p build/etc
  flex_mkdir "${ETC_NAMED_DIRSPEC}"
  flex_mkdir "${ETC_NAMED_DIRSPEC}"
  flex_mkdir "${ETC_NAMED_DIRSPEC}/${INSTANCE_SUBDIRPATH}"
  flex_mkdir "${INSTANCE_ETC_NAMED_DIRSPEC}/keys"
fi

echo "NOTE: There is no 'read-only' capability for remote daemon control"
echo "   of ISC Bind named/rndc."
echo
echo "NOTE: REMOTELY-IP-speaking, named.conf provides a way for"
echo "      a separate end-user and sysadmin to individually update their:"
echo "  * zones database"
echo "  * forwarder assignments"
echo
echo "Have QA, PCIC, PCI-DSS or Common Criteria folks? You should say 'y':"
echo "Keys and TSIGs will never be viewable at world file permission."
read -rp "Allow anyone within this host to view Bind configuration files? (N/y): " -iN
REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
if [ "$REPLY" == 'y' ]; then
  WORLD_READABLE=1
else
  WORLD_READABLE=0
fi

# Setting up instance-specific RNDC configuration and key files
HMAC_ALGORITHM="hmac-sha512"

# Generate RNDC keys
echo "Generating RNDC key ..."
rndc-confgen -a \
        -c "${BUILDROOT}${CHROOT_DIR}/$INSTANCE_RNDC_KEY_FILESPEC" \
        -A "$HMAC_ALGORITHM"
echo "Created ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_RNDC_KEY_FILESPEC"

filename="$RNDC_CONF_FILENAME"
filepath="$INSTANCE_RNDC_CONF_DIRSPEC"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/${filespec}"
cat << RNDC_MASTER_CONF | tee ${BUILDROOT}${CHROOT_DIR}/${filespec} > /dev/null
#
# File: ${filename}
# Path: ${filepath}
# Title: RNDC configuration file
# Generator: $(basename $0)
# Created on: $(date)
#
options {
	default-key "${RNDC_KEYNAME}";
	default-server 127.0.0.1;
	default-port ${RNDC_PORT};
	};

# Always hide keys from main config file
include "${INSTANCE_RNDC_KEY_FILESPEC}";
RNDC_MASTER_CONF
echo

flex_chmod 0640 "$filespec"
flex_chown "root:$GROUP_NAME" "$filespec"

filename="controls-named.conf"
filepath="$INSTANCE_ETC_NAMED_DIRSPEC"
filespec="${filepath}/$filename"
echo "Creating ${BUILDROOT}${CHROOT_DIR}/$filespec ..."
cat << NAMED_KEY_CONF | tee "${BUILDROOT}${CHROOT_DIR}/$filespec" > /dev/null
#
# File: ${filename}
# Path: ${filepath}
# Title: Control access to Bind9 (named) daemon by RNDC key 
# Description:
#   To be included by $INSTANCE_NAMED_CONF_FILESPEC file
# Generator: $(basename $0)
# Created on: $(date)
#
controls {
	inet 127.0.0.1 port ${RNDC_PORT} allow { 
		127.0.0.1/32;
       		} keys { 
			"${RNDC_KEYNAME}";
	       	};
	};

NAMED_KEY_CONF

flex_chmod 0640 "$filespec"
flex_chown "root:$GROUP_NAME" "$filespec"
echo


if [ $UID -eq 0 ]; then
  if [ -n "$CHROOT_DIR" ]; then
    # Check syntax of named.conf file
    named_chroot_opt="-t ${BUILDROOT}${CHROOT_DIR}"
  fi

  pushd .
  cd ${BUILDROOT}${CHROOT_DIR}
  $named_checkconf_filespec -c \
    -i \
    -p \
    -x \
    $named_chroot_opt \
    $INSTANCE_NAMED_CONF_FILESPEC \
    >/dev/null
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "File $INSTANCE_NAMED_CONF_FILESPEC did not pass syntax."
    $named_checkconf_filespec -c \
      -i \
      -p \
      -x \
      $named_chroot_opt \
      $INSTANCE_NAMED_CONF_FILESPEC
    echo "File $INSTANCE_NAMED_CONF_FILESPEC did not pass syntax."
    popd
    exit $retsts
  fi
  popd
  if [ $retsts -ne 0 ]; then
    exit $retsts
  else
    echo "Syntax-check passed for ${BUILDROOT}${CHROOT_DIR}/$INSTANCE_NAMED_CONF_FILESPEC"
  fi
else
  echo "NOTE: Unable to perform syntax-checking this in here."
  echo "      named-checkconf needs CAP_SYS_CHROOT capability in non-root $USER"
  echo "      ISC Bind9 Issue #3119"
  echo
  echo "When you finish moving settings into $ETC_NAMED_DIRSPEC, execute:"
  echo "  $named_checkconf_filespec -i -p -c -x $named_chroot_opt $INSTANCE_NAMED_CONF_FILESPEC"
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
  

if [ "$WORLD_READABLE" -eq 1 ]; then
  flex_chmod go+rx-w "$INSTANCE_ETC_NAMED_DIRSPEC"
  flex_chown root:${GROUP_NAME} "$INSTANCE_ETC_NAMED_DIRSPEC"

  flex_chmod go+r-wx "$INSTANCE_RNDC_CONF_FILESPEC"
  flex_chown root:${GROUP_NAME} "$INSTANCE_RNDC_CONF_DIRSPEC"

  flex_chmod go+r-wx "$INSTANCE_ETC_NAMED_DIRSPEC/named.conf"
  flex_chown root:${GROUP_NAME} "$INSTANCE_ETC_NAMED_DIRSPEC/named.conf"
  # file-ownership are set by other logics
  # need to chase 'include' statements within named.conf here
  # problem is that in build/, there is no named.conf
else
  flex_chmod o-rwx "$INSTANCE_ETC_NAMED_DIRSPEC"
  flex_chmod o-rwx "$INSTANCE_RNDC_CONF_FILESPEC"
  flex_chmod o-rwx "$INSTANCE_ETC_NAMED_DIRSPEC/named.conf"
fi

echo "Done."
