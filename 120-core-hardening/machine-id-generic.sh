#!/bin/bash
# File: machine-id-generic.sh
# Title: Make machine-id a generic one

echo "Making the 'machine-id' a generic one"
echo

GENERIC_MACHINE_ID="b08dfa6083e7567a1921a715000001fb"
echo "We are using this machine-id: ${GENERIC_MACHINE_ID}"

SYS_MACH_ID="/etc/machine-id"
echo "Writing $SYS_MACH_ID ..."
echo "${GENERIC_MACHINE_ID}" > "${SYS_MACH_ID}"


DBUS_MACH_ID="/etc/machine-id"
echo "Writing $DBUS_MACH_ID ..."
echo "${GENERIC_MACHINE_ID}" > "${DBUS_MACH_ID}"
echo

echo "Done."
