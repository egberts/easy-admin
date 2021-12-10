#!/bin/bash
# File: 122-cis-single-user.sh
# Title:  Ensure that single-user mode requires authentication
#
# Environment:
#   BUILDROOT - set to '/' to actually install directly into your filesystem
#
# Prerequisites:
#   grub (grub)
#   gawk (awk)
#   sudo (sudo)
#   coreutils (tee, chown, chmod, touch)
#
# References:
#   https://help.ubuntu.com/community/Grub2/Passwords

BUILDROOT=${BUILDROOT:-/tmp}
echo "Ensure that root is disabled"
echo ""
echo "Reading /etc/shadow..."
ROOT_PWD="$(sudo grep -E '^root:[*\!]+:' /etc/shadow)"
RETSTS=$?
if [ $RETSTS -eq 1 ] && [ -z "$ROOT_PWD" ]; then
  echo "FAIL: Root is not disabled."
  echo "Aborted."
  exit 1
else
  echo "PASS: Root account is disabled."
fi
echo ""

echo "Done."
exit 0
