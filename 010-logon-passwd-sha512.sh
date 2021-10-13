#!/bin/bash
# File: 010-logon-passwd-sha512.sh
# Title: Upgrade logon password to SHA512 hash
#
# Prerequisites:
#  grep (grep)
#  gawk (awk)
#

LOGIN_DEFS="/etc/login.defs"
if [ ! -f $LOGIN_DEFS ]; then
  echo "Missing $LOGIN_DEFS. Aborted"
  exit 9
fi

# Look for uncommented ENCRYPT_METHOD value
ENCRYPT_METHOD="$(grep -E '^\s*(~#)*\s*ENCRYPT_METHOD\s' $LOGIN_DEFS | awk '{print $2}')"
echo "Current setting of encryption method of logon passwords: $ENCRYPT_METHOD"

if [ "$ENCRYPT_METHOD" != "SHA512" ]; then
  echo "ERROR: Password encryption method '$ENCRYPT_METHOD' is not SHA512"
  echo "Aborted."
  exit 254
else
  echo "This current password encryption method '$ENCRYPT_METHOD' is good."
fi
echo "Done."
