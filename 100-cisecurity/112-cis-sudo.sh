#!/bin/bash
# File: 112-cis-sudo.sh
# Title: Ensure that sudo is deployed and configured
#

echo "Passively check if 'use_pty' exist in /etc/sudoers"
echo

sudo apt install sudo

# Check for 'use_pty', must exist to PASS
USE_PTY_SEEN="$(sudo grep -Ei '^\s*Defaults\s+([^#]+,\s*)?use_pty(,\s+\S+\s*)*(\s+#.*)?$' /etc/sudoers /etc/sudoers.d/*)"
RETSTS=$?
if [ $RETSTS -ne 0 ] || \
   [ -z "$USE_PTY_SEEN" ]; then
  echo "Missing 'Defaults use_pty' in /etc/sudoers"
  echo "FAIL"
  exit 254
else
  echo "In /etc/sudoers, 'Defaults use_ptr' exists."
fi
echo

echo "Done."
exit 0
