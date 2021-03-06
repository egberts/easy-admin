#!/bin/bash -x
# File: 486-net-ntp-chrony-mitm.sh
# Title: Add protections against MitM attack against NTP protocol
# Description:
#
# Reads:  nothing
# Modifies:  nothing
# Adds:
#   /etc/chrony/conf.d/50-chronyd_mitm_defense.conf
#
# ENVIRONMENT variables:
#   ANNOTATE
#   BUILDROOT
#   HAVE_IPV4
#   HAVE_IPV6
#
# Dependencies:
#   gawk (awk)
#   sudo
#   lsb-release (lsb_release)
#   findutils (xargs)???
#   coreutils (basename, chmod, chown, dirname, mkdir, sort, tee, touch)
#   util-linux (whereis)
#

BUILDROOT="${BUILDROOT:-build}"
source ./maintainer-ntp-chrony.sh

if [ "${BUILDROOT:0:1}" != '/' ]; then
  mkdir -p "$BUILDROOT"
else
  FILE_SETTING_PERFORM='true'
fi

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-setting-chronyd-mitm-defense.sh"

flex_ckdir "$ETC_DIRSPEC"
flex_ckdir "$extended_sysconfdir"
flex_ckdir "$CHRONY_CONFD_DIRSPEC"
flex_ckdir "$VAR_DIRSPEC"
flex_ckdir "$VAR_LIB_DIRSPEC"
flex_ckdir "$CHRONY_VAR_LIB_DIRSPEC"

DROP_IN_CONF_FILENAME="50-chronyd_mitm_defense.conf"
USERNAMES_LIST="_chrony chrony ntp"  # new Chrony

CHRONYD_BIN="$(whereis -b chronyd | awk -F: '{print $2}')"

# Auto determine username of Chrony by passwd probes
for this_username in $USERNAMES_LIST; do
  found_in_passwd="$(grep -e ^"${this_username}": /etc/passwd )"
  if [ -n "$found_in_passwd" ]; then
    USERNAME="$(echo "$found_in_passwd" | awk -F: '{print $1}')"
    break;
  fi
done

if [ -z "$USERNAME" ]; then
  echo "List of usernames not found: $USERNAMES_LIST"
  exit 9
fi
echo "Username '$USERNAME' found."
GROUPNAME="$USERNAME"


CHRONY_CONFD_DIR="${extended_sysconfdir}/conf.d"  # /etc/chrony/conf.d

ANNOTATE=${ANNOTATE:-y}


# Syntax: create_file file-permission owner:group
function create_file
{
  local dir_name
  local file_perm
  file_perm="$1"
  file_group_owner="$2"
  dir_name="$(dirname "$FILESPEC")"
  echo "Creating $FILESPEC file..."
  flex_touch "$FILESPEC"
  flex_chmod "$file_perm" "$FILESPEC"
  flex_chown "$file_group_owner" "$FILESPEC"
  cat << CREATE_FILE_EOF | tee "${BUILDROOT}$FILESPEC" >/dev/null
#
# File: $(basename "$FILESPEC")
# Path: $dir_name
# Title: $3
# Creator: $(basename "$0")
# Date: $(date)
# Description:
#
CREATE_FILE_EOF
  unset dir_name
  unset file_perm
  unset file_group_owner
}

function write_conf
{
  cat << WRITE_CONF_EOF | tee -a "${BUILDROOT}$FILESPEC" >/dev/null
$1
WRITE_CONF_EOF
}

function write_note
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << WRITE_NOTE_EOF | tee -a "${BUILDROOT}$FILESPEC" >/dev/null
$1
WRITE_NOTE_EOF
  fi
}

function write_note_makestep
{
  if [ "$ANNOTATE" = "y" ]; then
    cat << CHRONY_DROPIN_CONF_EOF | tee -a "${BUILDROOT}$FILESPEC" >/dev/null
# makestep threshold limit
#  Normally chronyd will cause the system to gradually correct any
#  time offset, by slowing down or speeding up the clock as required.
#  In certain situations, the system clock might be so far adrift that
#  this slewing process would take a very long time to correct the
#  system clock.
#
#  This directive forces chronyd to step the system clock if the
#  adjustment is larger than a threshold value, but only if there were
#  no more clock updates since chronyd was started than a specified
#  limit (a negative value can be used to disable the limit).
#
#  This is particularly useful when using reference clocks, because
#  the initstepslew directive works only with NTP sources.
#
#  An example of the use of this directive is:
#
#    makestep 0.1 3
#
#  This would step the system clock if the adjustment is larger than
#  0.1 seconds, but only in the first three clock updates.
#
CHRONY_DROPIN_CONF_EOF
  fi
}

function write_note_minsources
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << CHRONY_DROPIN_CONF_EOF | tee -a "${BUILDROOT}$FILESPEC" >/dev/null
# minsources sources
#   The minsources directive sets the minimum number of sources that
#   need to be considered as selectable in the source selection
#   algorithm before the local clock is updated. The default value is
#   1.
#
#   Setting this option to a larger number can be used to improve the
#   reliability. More sources will have to agree with each other and
#   the clock will not be updated when only one source (which could be
#   serving incorrect time) is reachable.
#
CHRONY_DROPIN_CONF_EOF
  fi
}

function write_note_maxchange
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << CHRONY_DROPIN_CONF_EOF | tee -a "${BUILDROOT}$FILESPEC" >/dev/null
# maxchange offset start ignore
#   This directive sets the maximum allowed offset corrected on a clock
#   update. The check is performed only after the specified number of
#   updates to allow a large initial adjustment of the system clock.
#   When an offset larger than the specified maximum occurs, it will be
#   ignored for the specified number of times and then chronyd will
#   give up and exit (a negative value can be used to never exit). In
#   both cases a message is sent to syslog.
#
#   An example of the use of this directive is:
#
#       maxchange 1000 1 2
#
#   After the first clock update, chronyd will check the offset on
#   every clock update, it will ignore two adjustments larger than 1000
#   seconds and exit on another one.
#
CHRONY_DROPIN_CONF_EOF
  fi
}

function write_note_maxdrift
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << CHRONY_DROPIN_CONF_EOF | tee -a "${BUILDROOT}$FILESPEC" >/dev/null
# maxdrift drift-in-ppm
#   This directive specifies the maximum assumed drift (frequency
#   error) of the system clock. It limits the frequency adjustment that
#   chronyd is allowed to use to correct the measured drift. It is an
#   additional limit to the maximum adjustment that can be set by the
#   system driver (100000 ppm on Linux, 500 ppm on FreeBSD, NetBSD, and
#   macOS 10.13+, 32500 ppm on Solaris).
#
#   By default, the maximum assumed drift is 500000 ppm, i.e. the
#   adjustment is limited by the system driver rather than this
#   directive.
#
CHRONY_DROPIN_CONF_EOF
  fi
}

function write_note_maxslewrate
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << CHRONY_DROPIN_CONF_EOF | tee -a "${BUILDROOT}$FILESPEC" >/dev/null
# maxslewrate rate-in-ppm
#   The maxslewrate directive sets the maximum rate at which chronyd is
#   allowed to slew the time. It limits the slew rate controlled by the
#   correction time ratio (which can be set by the corrtimeratio
#   directive) and is effective only on systems where chronyd is able
#   to control the rate (i.e. all supported systems with the exception
#   of macOS 12 or earlier).
#
#   For each system there is a maximum frequency offset of the clock
#   that can be set by the driver. On Linux it is 100000 ppm, on
#   FreeBSD, NetBSD and macOS 10.13+ it is 5000 ppm, and on Solaris it
#   is 32500 ppm. Also, due to a kernel limitation, setting maxslewrate
#   on FreeBSD, NetBSD, macOS 10.13+ to a value between 500 ppm and
#   5000 ppm will effectively set it to 500 ppm.
#
#   In early beta releases of macOS 13 this capability is disabled
#   because of a system kernel bug. When the kernel bug is fixed,
#   chronyd will detect this and re-enable the capability (see above
#   limitations) with no recompilation required.
#
#   By default, the maximum slew rate is set to 83333.333 ppm (one
#   twelfth).
#
CHRONY_DROPIN_CONF_EOF
  fi
}

function write_note_ntsdumpdir
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << CHRONY_DROPIN_CONF_EOF | tee -a "${BUILDROOT}$FILESPEC" >/dev/null
# ntsdumpdir directory
#   This directive specifies a directory for the client to save NTS
#   cookies it received from the server in order to avoid making an
#   NTS-KE request when chronyd is started again. The cookies are saved
#   separately for each NTP source in files named by the IP address of
#   the NTS-KE server (e.g. 1.2.3.4.nts). By default, the client does
#   not save the cookies.
#
#   If the directory does not exist, it will be created automatically.
#
#   An example of the directive is:
#
#   ntsdumpdir /var/lib/chrony
#
#   This directory is used also by the NTS server to save keys.
#
CHRONY_DROPIN_CONF_EOF
  fi
}

function write_note_ntsdumpdir
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << CHRONY_DROPIN_CONF_EOF | tee -a "${BUILDROOT}$FILESPEC" >/dev/null
# rtcsync
#   The rtcsync directive enables a mode where the system time is
#   periodically copied to the RTC and chronyd does not try to track
#   its drift. This directive cannot be used with the rtcfile
#   directive.
#
#   On Linux, the RTC copy is performed by the kernel every 11 minutes.
#
#   On macOS, chronyd will perform the RTC copy every 60 minutes when
#   the system clock is in a synchronised state.
#
#   On other systems this directive does nothing.
#
CHRONY_DROPIN_CONF_EOF
  fi
}

#################################################
# All done with querying of user-input on about
# the administrator/administration part of NTP
#################################################
FILENAME="$DROP_IN_CONF_FILENAME"
FILEPATH="$CHRONY_CONFD_DIR"
FILESPEC="$FILEPATH/$FILENAME"

create_file 0640 "${USERNAME}:${GROUPNAME}" \
    "Protection of NTP protocol against Man-in-the-Middle"
#####################################################

# minimum setting to reduce impact of MitM NTP attacks
# TODO: do we need a minimum of 2 NTP servers for these settings?

# Add 'nts' to 'server's
# Add 'maxdelay 0.05/0.1/0.2' across 'server's
# Add 'iburst' across 'server's
# write_conf  "server x.example.net iburst nts maxdelay 0.1")
# write_conf  "server y.example.net iburst nts maxdelay 0.2")
# write_conf  "server z.example.net iburst nts maxdelay 0.05")
# Move above to net-ntp-chrony-conf-pool???

# Add minimum number of NTP sources before time is sync'd
# 'minsources 3'
# Maybe it goes into net-ntp-chrony-conf-main???
# write_note_minsources
# write_note "# Minimum number of NTP sources before the time is considered synced"
# write_conf  "minsources 3")
# Move above to net-ntp-chrony-conf-pool???

MAX_CHANGE=100
MAX_CHANGE_OFFSET=0
MAX_CHANGE_START=0
write_note_maxchange
write_note "# After the first clock update, chronyd will check the offset on"
write_note "# every clock update, it will ignore $MAX_CHANGE_IGNORE adjustments larger than $MAX_CHANGE"
write_note "# seconds and exit on another $MAX_CHANGE_START."
write_conf "maxchange $MAX_CHANGE $MAX_CHANGE_OFFSET $MAX_CHANGE_START"

# Make tinyer steps
MAKESTEP_THRESHOLD=0.001
MAKESTEP_LIMIT=1
write_note_makestep
write_note "# This would step the system clock if the adjustment is larger than"
write_note "# $MAKESTEP_THRESHOLD seconds, but only in the first $MAKESTEP_LIMIT clock updates."
write_conf "makestep ${MAKESTEP_THRESHOLD} ${MAKESTEP_LIMIT}"

# Make drift maximum at 100
MAXDRIFT_LIMIT=100
write_note_maxdrift
write_note "# The adjustment of drift is limited to ${MAXDRIFT_LIMIT} ppm."
write_conf "maxdrift $MAXDRIFT_LIMIT"

# Cap slew rate at 100
MAX_SLEW_RATE_PPM=100
write_note_maxslewrate
write_note "# The maximum rate of slewing time is $MAX_SLEW_RATE_PPM ppm."
write_conf "maxslewrate $MAX_SLEW_RATE_PPM"

# Set dump directory at /var/lib/chrony
# 'ntsdumpdir /var/lib/chrony'
# write_conf  "ntsdumpdir /var/lib/chrony")
# Move to net-ntp-chrony-ntpsec???

# Update hardware clock from OS/system clock
# 'rtcsync'
write_note "# Set hardware clock after reading from its OS clock"
write_conf "rtcsync"

# last line is always empty
write_note ""

echo "Done writing $FILESPEC."
echo

echo "Verifying syntax of Chrony config files..."
# Verify the configuration files to be correct, syntax-wise.
$CHRONYD_BIN -p -f "${BUILDROOT}$FILESPEC" >/dev/null 2>&1
retsts=$?
if [ "$retsts" -ne 0 ]; then
  # do it again but verbosely
  $CHRONYD_BIN -p -f "${BUILDROOT}$FILESPEC"
  echo "ERROR: ${BUILDROOT}$FILESPEC failed syntax check."
  exit 13
fi
echo "${BUILDROOT}$FILESPEC passes syntax-check"
echo

echo "Reloading config file in chronyd daemon..."
chronyc reload sources >/dev/null 2>&1
retsts=$?
if [ "$retsts" -ne 0 ]; then
  systemctl --quiet is-enabled "$chrony_systemd_unit_name"
  retsts=$?
  if [ "$retsts" -ne 0 ]; then
    systemctl enable "$chrony_systemd_unit_name"
  fi
  systemctl --quiet is-active "$chrony_systemd_unit_name"
  retsts=$?
  if [ "$retsts" -ne 0 ]; then
    systemctl try-reload-or-restart "$chrony_systemd_unit_name"
  else
    systemctl start "$chrony_systemd_unit_name"
  fi
fi
echo "Done."
exit 0
