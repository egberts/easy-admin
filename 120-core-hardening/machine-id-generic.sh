#!/bin/bash
# File: machine-id-generic.sh
# Title: Make machine-id a generic one
# Description:
#   Deal with systemd's insistence of having a unique Machine ID file
#   We use a common Machine ID provided by Whonix to ensure maximum privacy
#
# Privilege required: root
# OS: Debian
# Kernel: Linux
#
# Files impacted:
#  read   - /etc/machine-id
#           /var/lib/dbus/machine-id
#  create - /etc/machine-id
#         - /var/lib/dbus/machine-id
#  modify - /etc/machine-id
#         - /var/lib/dbus/machine-id
#  delete - none
#
# Environment Variables:
#    None
#
# Prerequisites (package name):
#   none
#
# References:
#   https://github.com/Kicksecure/dist-base-files
#   https://github.com/Kicksecure/dist-base-files/blob/master/etc/machine-id
#

GENERIC_MACHINE_ID="b08dfa6083e7567a1921a715000001fb"
ETC_MACHINE_ID_FILESPEC="/etc/machine-id"
DBUS_MACHINE_ID_FILESPEC="/var/lib/dbus/machine-id"

function verify_machine_id
{
  local MACHINE_ID_FILESPEC=$1
  
  #  check that file exist
  echo "File to verify: $MACHINE_ID_FILESPEC"
  if [ ! -f "$MACHINE_ID_FILESPEC" ]; then
    echo "ERROR: File $MACHINE_ID_FILESPEC is not found; aborted."
    exit 9
  fi
  
  # check that file is readable
  echo "File: $MACHINE_ID_FILESPEC is found."
  if [ ! -r "$MACHINE_ID_FILESPEC" ]; then
    echo "ERROR: File $MACHINE_ID_FILESPEC is not readable; aborted."
    exit 9
  fi
  echo "File: $MACHINE_ID_FILESPEC is readable."

  # check that Machine ID is generic
  local OLD_MACHINE_ID="$(cat -v "$MACHINE_ID_FILESPEC")"
  if [ "$OLD_MACHINE_ID" == "$GENERIC_MACHINE_ID" ]; then
    echo "PASS: Machine ID $OLD_MACHINE_ID is a Whonix Generic Machine ID"
    return 0
  else
    echo "ERROR: Machine ID is mismatched"
    echo "ERROR: Current Machine ID is $OLD_MACHINE_ID"
    echo "ERROR: Desired Machine ID is $GENERIC_MACHINE_ID"
  fi
  return 1
}

function write_machine_id
{
  local MACHINE_ID_FILESPEC=$1
  if [ ! -w "$MACHINE_ID_FILESPEC" ]; then
    echo "ERROR: Unable to write to $MACHINE_ID_FILESPEC"
    exit 14
  fi
  echo "Writing $MACHINE_ID_FILESPEC ..."
  echo "${GENERIC_MACHINE_ID}" >"${SYS_MACH_ID}"
}

echo "Checking the Machine ID file for generic ID"
echo

verify_machine_id $ETC_MACHINE_ID_FILESPEC
verify_machine_id $DBUS_MACHINE_ID_FILESPEC

write_machine_id $ETC_MACHINE_ID_FILESPEC
write_machine_id $DBUS_MACHINE_ID_FILESPEC
echo
echo "Done."
