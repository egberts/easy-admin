#!/bin/bash
# File: 010-logon-passwd-argon2id.sh
# Title: Upgrade logon password to Argon2id hash
#
# Prerequisites:
#  grep (grep)
#  gawk (awk)
#
echo "Check system password datastore for adequate encryption of login password"
echo ""

LOGIN_DEFS="/etc/login.defs"
if [ ! -f $LOGIN_DEFS ]; then
  echo "Missing $LOGIN_DEFS. Aborted"
  exit 9
fi

# Look for uncommented ENCRYPT_METHOD value
ENCRYPT_METHOD="$(grep -E '^\s*(~#)*\s*ENCRYPT_METHOD\s' $LOGIN_DEFS | awk '{print $2}')"
echo "Current setting of encryption method of logon passwords: $ENCRYPT_METHOD"
echo ""

if [ "$ENCRYPT_METHOD" != "argon2id" ]; then
  echo "ERROR: Password encryption method '$ENCRYPT_METHOD' is not Argon2id"
  echo "Aborted."
  exit 254
else
  echo "This current password encryption method '$ENCRYPT_METHOD' is good."
fi
echo ""
echo "Done."
