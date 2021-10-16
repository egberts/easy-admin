#!/bin/bash
# File: 380-systemd-journal.sh
# Title: Set a comfortable level of journalctl usage
# Description:
#   At least make the disk-space usage by systemd-journal a
#   bit more managable.
#   Perhaps fold that terminal output to its current screen-width.

SYSD_JOURNAL_CONF_D="/etc/systemd/journald.conf.d/"

# Set environment variable for systemd LESS
FILENAME="80-systemd-journalctl-fold-to-screen-width"
FILEPATH="/etc/profile.d"
FILESPEC="$FILEPATH/$FILENAME"
echo "Writing $FILESPEC file ..."
cat << BASHRC_EOF | sudo tee "$FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${FILEPATH}
# Creator: $(realpath "$0")
# Date: $(date)
#
export SYSTEMD_LESS=FRXMK

BASHRC_EOF

journalctl -b -u systemd-journald

# Create a drop-in config directory for systemd-journald
if [ ! -d "$SYSD_JOURNAL_CONF_D" ]; then
  sudo mkdir "$SYSD_JOURNAL_CONF_D"
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "Unable to create $SYSD_JOURNAL_CONF_D directory"
    exit $RETSTS
  fi
fi

echo "You are using a lot of System journal."
echo "We will trim that down to 50MB using a drop-in config snippet."
FILENAME="00-journal-size.conf"
FILEPATH="$SYSD_JOURNAL_CONF_D"
FILESPEC="$FILEPATH/$FILENAME"
echo "This file is called $FILENAME and is located in $FILEPATH."
echo "Writing $FILESPEC file ..."
cat << JOURNAL_EOF | sudo tee "$FILESPEC"
#
# File: ${FILENAME}
# Path: ${FILEPATH}
# Title: Cap the systemd journal size to a specific size
# Creator: $(realpath "$0")
# Date: $(date)
#
[Journal]
SystemMaxUse=50M

JOURNAL_EOF

echo "Also, we can send all system journal outputs toward terminal tty12"
echo " (or virtual terminal 12). You will be able press F12 to view that "
echo "journal output."
FILENAME="fw-tty12.conf"
FILEPATH="$SYSD_JOURNAL_CONF_D"
FILESPEC="$FILEPATH/$FILENAME"
cat << JOURNAL_EOF | sudo tee "$FILESPEC"
#
# File: ${FILENAME}
# Path: ${FILEPATH}
# Title: Send all systemd journal outputs to virtual terminal 12
# Creator: $(realpath "$0")
# Date: $(date)
#
[Journal]
ForwardToConsole=yes
TTYPath=/dev/tty12
MaxLevelConsole=info

JOURNAL_EOF

systemctl restart systemd-journald.service

echo "Next time you run 'journalctl', LESS terminal output will be wrap-folded"
echo ""
echo "Some commands to try:"
echo "  journal -x  # include explanation of messsages"
echo "  journalctl --since=\"2021-08-23 00:00:00\""
echo "  journalctl --since \"20 min ago\""
echo "  journalctl -f  # follow new log messages"
echo "  journalctl /usr/bin/dhclient  # show all msgs by a specific binary"
echo "  journalctl _PID=1  # show all message by a specific process"
echo "  journalctl -u hostapd.service  # show all messages by specific unit"
echo "  journalctl --user -u dbus  # show all msg from user service by specific unit"
echo "  journalctl -k  # do a legacy 'dmesg'"
echo "  journalctl -p err..alert  # show only error, critical and alert msgs"
echo "  journalctl --vacuum-size=100M  # reduce journals to below 100MB"
echo "  journalctl --vacuum-time=2weeks  # reduce journals to below 2 weeks"
