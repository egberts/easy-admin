#!/bin/bash
# File: 113-cis-sudo-log.sh
# Title: Ensure that sudo has its own log file
#

echo "Actively check that a logfile exist just for sudo ..."
echo

# Check for 'use_pty', must exist to PASS
LOGFILE_SEEN="$(sudo grep -Ei '^\s*Defaults\s+logfile=\S+' /etc/sudoers /etc/sudoers.d/*)"

if [ -z "$LOGFILE_SEEN" ];then
  echo "ERROR: Missing 'Defaults logfile=' in /etc/sudoers; aborted."
  exit 254
else
  echo "In /etc/sudoers and /etc/sudoers.d/*, 'Defaults logfile=' found."
fi

# Extract 'Defaults logfile=' from /etc/sudoers and /etc/sudoers.d/*
# use 'sudo -n -l' to get ALL config settings
# use 'sudo' to do this from within root user
SETTINGS="$(sudo -i sudo -n -l | grep logfile)"

# if settings is empty, we got a major SUDO problem
if [ -z "$SETTINGS" ]; then
  echo "ERROR: sudo config is empty; aborted."
  exit 3
fi

for THIS_SETTING in $SETTINGS; do
  if [[ "$THIS_SETTING" == "logfile="* ]]; then
    # extract logfile= value from assignment
    SUDO_LOG_FILESPEC="${THIS_SETTING#*=}"
  fi
done

# Check file existance of filespec in 'logfile=<filespec>'
if [ ! -f "$SUDO_LOG_FILESPEC" ]; then
  echo "ERROR: File $SUDO_LOG_FILESPEC is missing; aborted."
  exit 9
else
  echo "File $SUDO_LOG_FILESPEC exist"
fi

# Check file permission of filespec in 'logfile=<filespec>'
if [ "$(stat -c %a "${SUDO_LOG_FILESPEC}")" != "600" ]; then
  echo "File permission of $SUDO_LOG_FILESPEC file is not SAFE!"
  ls -lat "$SUDO_LOG_FILESPEC"
  echo "Changing file to 0600 mode ..."
  sudo chmod 0600 "$SUDO_LOG_FILESPEC"
fi

# Check file ownership of filespec in 'logfile=<filespec>'
SUDO_LOGFILE_UID="$(stat --print=%u "${SUDO_LOG_FILESPEC}")"
if [ "$SUDO_LOGFILE_UID" != "0" ]; then
  echo "WARNING: logfile $SUDO_LOG_FILESPEC not user-owned by root; aborted."
  exit 11
fi
SUDO_LOGFILE_GID="$(stat --print=%g "${SUDO_LOG_FILESPEC}")"
if [ "$SUDO_LOGFILE_GID" != "0" ]; then
  echo "WARNING: logfile $SUDO_LOG_FILESPEC not group-owned by root; aborted."
  exit 11
fi
echo

echo "PASS: Done."
exit 0
