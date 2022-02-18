#!/bin/bash
# File: 800-cron-no-users.sh
# Title: Block non-root users from creating cron jobs
# Description:
#
echo "Block non-root users from creating cron jobs"
echo
echo "Most useful in preventing the introduction of persistent malware"
echo

cron_allow_filespec="/etc/cron.allow"

# check if file exist
if [ -a "$cron_allow_filespec" ]; then
  # check if file is a regular type
  if [ -f "$cron_allow_filespec" ]; then
    # check if file is not empty
    if [ -s "$cron_allow_filespec" ]; then
      echo "WARNING: Something is in '${cron_allow_filespec}' file."
      echo "You should examine this file to ensure no persistent malware."
      echo "Aborted."
      exit 13
    else
      echo "File '${cron_allow_filespec}' is a regular file that is "
      echo "properly empty and root-owned."
    fi
  else
    echo "WARNING: File '${cron_allow_filespec}' is NOT a regular file."
    echo "You should examine this file to ensure no persistent malware."
    echo "Aborted."
  fi
else
  if [ $UID -ne 0 ]; then
    echo "will perform sudo to block non-root users from creating cron jobs."
    sudo touch "$cron_allow_filespec"
  else
    echo "Creating $cron_allow_filespec ..."
    touch /etc/cron.allow
  fi
fi
echo
echo "Done."
