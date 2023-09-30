#!/bin/bash
# File: 011-su-logfile.sh
# Title: Check for valid logfile used by /usr/bin/su
# Description:
#   TBD
#
# Privilege required: none
# OS: Debian
# Kernel: Linux
#
# Files impacted:
#  read   - /etc/login.defs
#  create - none
#  modify - none
#  delete - none
#
# Environment Variables:
#   none
#
# Prerequisites (package name):
#   awk (mawk)
#   grep (grep)
#   stat (coreutils)
#
# References:
#


SULOG_FILE_CHMOD_EXPECTED=600
SULOG_FILE_CHOWN_EXPECTED=root
SULOG_FILE_CHGRP_EXPECTED=root

echo "Check login daemon for proper logfile"
echo ""

LOGINDEFS_FILESPEC="/etc/login.defs"
if [ ! -f $LOGINDEFS_FILESPEC ]; then
  echo "Missing $LOGINDEFS_FILESPEC. Aborted"
  exit 9
fi

# Look for invalid MD5_CRYPT_ENAB
MD5_CRYPT_ENAB="$(grep -E '^\s*(~#)*\s*MD5_CRYPT_ENAB\s' $LOGINDEFS_FILESPEC | awk '{print $2}')"
if [ "$MD5_CRYPT_ENAB" == "yes"  ]; then
  echo "ERROR: MD5_CRYPT_ENAB=yes must be commented out in $LOGINDEFS_FILESPEC"
  exit 3
fi
echo "MD5_CRYPT_ENAB= is not found in $LOGINDEFS_FILESPEC: (secured)"

# Look for uncommented SULOG_FILE value
SULOG_FILE_FILESPEC="$(grep -E '^\s*(~#)*\s*SULOG_FILE\s' $LOGINDEFS_FILESPEC | awk '{print $2}')"
if [ -z "$SULOG_FILE_FILESPEC" ]; then
  echo "SULOG_FILE= is missing a value in $LOGINDEFS_FILESPEC"
  echo "Typically, it has /var/log/sulog or /var/log/sulogin filespec value"
  exit 3
fi
echo "Found SULOG_FILE=$SULOG_FILE_FILESPEC in $LOGINDEFS_FILESPEC (correct)"

if [ ! -f "$SULOG_FILE_FILESPEC" ]; then
  echo "ERROR: SU_LOGFILE $SULOG_FILE_FILESPEC does not exist"
  exit 9
fi

SULOG_FILE_CHMOD="$(stat -c%a "$SULOG_FILE_FILESPEC")"
if [ "$SULOG_FILE_CHMOD" != "$SULOG_FILE_CHMOD_EXPECTED" ]; then
  echo "ERROR: File $SULOG_FILE_FILESPEC has incorrect file permission $SULOG_FILE_CHMOD"
  echo "ERROR: File permission should be $SULOG_FILE_CHMOD_EXPECTED"
  exit 11
fi
echo "File permission: $SULOG_FILE_CHMOD (correct)"

SULOG_FILE_CHOWN="$(stat -c%U "$SULOG_FILE_FILESPEC")"
if [ "$SULOG_FILE_CHOWN" != "$SULOG_FILE_CHOWN_EXPECTED" ]; then
  echo "ERROR: File $SULOG_FILE_FILESPEC has incorrect user owner: $SULOG_FILE_CHOWN"
  echo "ERROR: File user ownership should be $SULOG_FILE_CHOWN_EXPECTED"
  exit 11
fi
echo "File ownership:  $SULOG_FILE_CHOWN (correct)"

SULOG_FILE_CHGRP="$(stat -c%G "$SULOG_FILE_FILESPEC")"
if [ "$SULOG_FILE_CHGRP" != "$SULOG_FILE_CHGRP_EXPECTED" ]; then
  echo "ERROR: File $SULOG_FILE_FILESPEC has incorrect user owner: $SULOG_FILE_CHGRP"
  echo "ERROR: File user ownership should be $SULOG_FILE_CHGRP_EXPECTED"
  exit 11
fi
echo "File group name: $SULOG_FILE_CHGRP (correct)"


echo ""
echo "Done."
