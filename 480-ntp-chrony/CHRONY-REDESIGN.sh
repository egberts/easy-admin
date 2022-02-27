#
#  We split this up into other bash files
#    - chrony.conf (main)
#    - pool/server/peer (pool)
#    - admin
#    - MitM protection (mitm)
#    - RTC/PTP (ptp)
#
#   Goal is to make a basic but generic chrony.conf alone
#   All other refinements gointo the drop-in '/etc/chrony/conf.d'
#     - Moved 'pool' into a drop-in config file
#     - Moved hwclk settings into a drop-inconfig file
#
# Reads: nothing
# Changes: nothing
# Adds:
#    ${BUILDROOT}${CHROOT_DIR}/etc/chrony
#    ${BUILDROOT}${CHROOT_DIR}/etc/chrony/conf.d
#    ${BUILDROOT}${CHROOT_DIR}/etc/chrony/sources.d
#    ${BUILDROOT}${CHROOT_DIR}/etc/chrony/chrony.conf
#    ${BUILDROOT}${CHROOT_DIR}/var/lib/chrony/chrony.drift
#

BUILDROOT=""

source ./maintainer-chrony.sh

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-settings-chrony.sh"
rm -f "$FILE_SETTINGS_FILESPEC"

# Create the directories for Chrony daemon to use
# /etc/chrony
flex_mkdir "$CHRONY_CONF_DIRSPEC"
flex_chown "${CHRONYD_USER_NAME}:$CHRONYD_GROUP_NAME" "$CHRONY_CONF_DIRSPEC"
flex_chmod 0750 "$CHRONY_CONF_DIRSPEC"

# /etc/chrony/conf.d
flex_mkdir "$CHRONY_CONFD_DIRSPEC"
flex_chown "${CHRONYD_USER_NAME}:$CHRONYD_GROUP_NAME" "$CHRONY_CONFD_DIRSPEC"
flex_chmod 0750 "$CHRONY_CONFD_DIRSPEC"

# /etc/chrony/sources.d
flex_mkdir "$CHRONY_SOURCESD_DIRSPEC"
flex_chown "${CHRONYD_USER_NAME}:$CHRONYD_GROUP_NAME" "$CHRONY_SOURCESD_DIRSPEC"
flex_chmod 0750 "$CHRONY_SOURCESD_DIRSPEC"

# Create the basic but workable yet standalone chrony config file
cat << CHRONY_CONF_EOF | $SUDO_BIN tee 2>/dev/null "${BUILDROOT}${CHROOT_DIR}$CHRONY_CONF_FILESPEC"
#
# File: $(basename $CHRONY_CONF_FILESPEC)
# Path: $(realpath -m $(dirname $CHRONY_CONF_FILESPEC))
# Title: Chrony configuration file
#

# Pick up DHCP's ntpserver setting(s), if any
confdir ${CHRONY_DHCP_DIRSPEC}

# ADD ALL THE THINGS!
confdir ${CHRONY_CONFD_DIRSPEC}
# Any configuration can be replaced in later settings within this file

# Our trusty source(s)
# Use NTP sources found in the /etc/chrony/sources.d subdirectory.
sourcedir ${CHRONY_SOURCESD_DIRSPEC}

# This driftfile directive specify the location of the file that
# contains ID/key-pair used for NTP authentication.
keyfile /etc/chrony/chrony.keys

# This driftfile directive specify the file into which chronyd
# will store the rate information
driftfile /var/lib/chrony/chrony.drift

# Save NTS keys and cookies.
ntsdumpdir /var/lib/chrony

# Log files location.
logdir /var/log/chrony

# Stop bad estimates that are upsetting machine clock
maxupdateskew 100.0

# This directive enables kernel synchronization (every 11 minutes)
# of the real-time clock.  NOTE: This keyword cannot used  along
# with the 'rtcfile' directive: choose one.
rtcsync

# Steps the system clock instead of slewing it if the adjustment is
# larger than one second, but only in the first three clock updates
makestep 1 3
# Get TAI-UTC offset and leap second from the system TZ database
# This directive must be commented out when using time source serving
# leap-smeared time.
leapsectz 0
# Set the default access for all NTP commands to 'nobody'
cmddeny all


CHRONY_CONF_EOF
flex_chown "${CHRONYD_USER_NAME}:$CHRONYD_GROUP_NAME" "$CHRONY_CONF_FILESPEC"
flex_chmod 0750 "$CHRONY_CONF_FILESPEC"
