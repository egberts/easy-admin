#!/bin/bash
# File: 113-cis-sudo-log.sh
# Title: Ensure that sudo has its own log file
#

# Check for 'use_pty', must exist to PASS
LOGFILE_SEEN="$(sudo grep -Ei '^\s*Defaults\s+logfile=\S+' /etc/sudoers /etc/sudoers.d/*)"

if [ -z "$LOGFILE_SEEN" ];then
  echo "Missing 'Defaults logfile=' in /etc/sudoers"
  echo "FAIL"
  exit 254
else
  echo "In /etc/sudoers, 'Defaults logfile=' exists."
fi

# TODO: Check file permission of filespec in 'logfile=<filespec>'
echo "Done."
exit 0
