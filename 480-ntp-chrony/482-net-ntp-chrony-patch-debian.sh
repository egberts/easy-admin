#!/bin/bash
# File: 485-net-ntp-chrony.sh
# Title: Relocate debian-assigned pool fron chrony.conf into sources.d/ subdir
# Description:
#   Relocates any peer/server/pool into the sources.d/ subdir
#
#   - Locate chrony.conf
#   - Scan chrony.conf for 'pool'/'server'/'peer' directives
#   - Find all 'sourcedir' directive in chrony.conf
#   - Ignore 'sourcedir's that does not belong to chrony
#   - Remove duplicate hostnames
#   - Find an alternative place to relocate these 'pool'/'server'/'peer'
#   - Edit those founded lines out of chrony.conf
#   - Search for pre-existing entries of 'founded' IPs in conf.d/sources.d
#   - Any remaining founded, create a drop-in in sources.d/debian-stock-XXXXX.sources
#
# Shell UID requirement:  Any username
#
# Reads:
#   /etc/chrony/chrony.conf
#   /etc/chrony/sources.d/* is only consulted by 'chronyc reload sources'
# Changes:
#   /etc/chrony/chrony.conf
#   /etc/chrony/sources.d
# Adds:
#   /etc/chrony/sources.d/*
#
DEFAULT_DROPIN_CONF_FILENAME="debian-stock-pool.sources"

sysconfdir="/etc"
localstatedir="/"

DEFAULT_CHRONY_CONF_FILENAME="chrony.conf"
DEFAULT_CHRONY_SOURCESD_DIRPATH="$CHRONY_CONF_DIRPATH/sources.d"


CHRONY_CONF_DIRPATH="$sysconfdir/chrony"

CHRONY_CONF_FILESPEC="$CHRONY_CONF_DIRPATH/$DEFAULT_CHRONY_CONF_FILENAME"

SRC_SUFFIX="sources"

echo "This script patches the Debian-version of Chrony configuration file."
echo "It simply relocates the 'pool' directive from the main"
echo "configuration file into one of those drop-in config directory."
echo ""

####################################################################
# Defensive coding between NTP clients
####################################################################

# USERNAMES_LIST="_named bind9 bind named"  # new ISC Bind9
# USERNAMES_LIST="_ntp ntp chrony"  # new NTP
USERNAMES_LIST="_chrony chrony ntp"  # new Chrony

for this_username in $USERNAMES_LIST; do
  found_in_passwd="$(grep -e ^"${this_username}": /etc/passwd )"
  if [ -n "$found_in_passwd" ]; then
    CHRONY_USER="$(echo "$found_in_passwd" | awk -F: '{print $1}')"
    CHRONY_GROUP="$(id -G -n "$CHRONY_USER")"
    break;
  fi
done

if [ -z "$CHRONY_USER" ]; then
  echo "List of usernames not found: $USERNAMES_LIST"
  exit 9
fi
echo "Username '$CHRONY_USER' found."


##############################################################
# Chrony infrastructure
##############################################################
#
# Find the Chrony config file.
if [ ! -f "$CHRONY_CONF_FILESPEC" ]; then
  echo "Ummm, Chrony is missing the $CHRONY_CONF_FILESPEC file."
  exit 9
fi

# Scan chrony.conf for 'pool'/'server'/'peer'
# Make a list of all 'pool' found only in chrony.conf
# Find the unique list of hostnames in 'pool' directives only in chrony.conf
# Splitting into 4 words, no
# Bunching into 1 element, no
# Need two elements, two rows, two words each row

# Special bash programming for reading multiple words into each array indice
# these three fewest lines can enable reading multiple words per array indice
# than any other snippet of bash programming can.
# Unfortunately, there is no in-bash programming to do this multiple words
# per array indice directly from a file, after grepping.
echo ""
echo "Reading ${CHRONY_CONF_FILESPEC}..."
TMPFILE=/tmp/junk
grep -E '^\s*pool' $CHRONY_CONF_FILESPEC > $TMPFILE
readarray -t  RELOCATE_POOL_DIRECTIVES_A < $TMPFILE
rm $TMPFILE

if [ "${#RELOCATE_POOL_DIRECTIVES_A[*]}" -eq 0 ]; then
  echo "No 'pool' directives found in '$CHRONY_CONF_FILESPEC'. Aborted."
  exit 9
fi
echo "Found ${#RELOCATE_POOL_DIRECTIVES_A[*]} 'pool' directives..."

echo ""
# Find all 'sourcedir' directives in chrony.conf
echo "Searching for 'sourcedir' directives..."
SOURCES_DIRPATHS_A=($(grep -E '^(\s*(~#)*\s*sourcedir\s)' "$CHRONY_CONF_FILESPEC" | awk '{print $2}'| xargs))
echo "Number of 'sourcedir' directives found: ${#SOURCES_DIRPATHS_A[@]}"
echo "Sourced dirs found: ${SOURCES_DIRPATHS_A[*]}"

# Ignore 'sourcedir's that does not belong to chrony
CHRONY_SOURCES_DIRPATHS_A=()
for this_src_dir in ${SOURCES_DIRPATHS_A[*]}; do
  #echo "Testing $this_src_dir..."
  DIR_USER="$(stat -c '%U' $this_src_dir)"
  if [ "$DIR_USER" == "$CHRONY_USER" ]; then
    if [[ "$this_src_dir" = *"dhcp"* ]]; then
      echo "Skipping $this_src_dir as too DHCP-related..."
      continue
    fi
    CHRONY_SOURCES_DIRPATHS_A+=("$this_src_dir")
  else
    echo "Skipping $this_src_dir as non-Chrony-owned..."
    continue
  fi
done

CHRONY_SOURCESD_DIRPATH="${CHRONY_SOURCES_DIRPATHS_A[0]}"
# Choose first dirpath found
if [ ${#CHRONY_SOURCES_DIRPATHS_A[@]} -gt 1 ]; then
  echo "Too many Chrony sources.d subdirectories to choose from..."
fi
echo "Choosing '$CHRONY_SOURCESD_DIRPATH' subdirectory..."

# if Debian, Comment out all pools from stock Debian config
if [ -z "$CHRONY_SOURCESD_DIRPATH" ]; then
  echo "This is not the latest Debian chrony, for there are no 'chrony.d' subdir."
  echo "Aborted."
  exit 9
fi
echo ""

echo "New drop-in filename: $DEFAULT_DROPIN_CONF_FILENAME"
DROPIN_SOURCE_FILESPEC="$CHRONY_SOURCESD_DIRPATH/$DEFAULT_DROPIN_CONF_FILENAME"



function stop_disable_sysd()
{
  ACTIVE="$(systemctl is-active "${1}" >/dev/null 2>&1)"
  if [ "${ACTIVE}" == "active" ]; then
    sudo systemctl stop "${1}"
  fi
  ENABLED="$(systemctl is-enabled "${1}" >/dev/null 2>&1)"
  if [ "${ENABLED}" == "enabled" ]; then
    sudo systemctl disable "$1"
  fi
}


################################################################
# Drop-in config files
################################################################

touch "$DROPIN_SOURCE_FILESPEC"
chmod 0640 "$DROPIN_SOURCE_FILESPEC"
chown "${CHRONY_USER}:${CHRONY_GROUP}" "$DROPIN_SOURCE_FILESPEC"
echo "Creating '$DROPIN_SOURCE_FILESPEC' drop-in config file..."
cat << DROPIN_EOF | sudo tee "$DROPIN_SOURCE_FILESPEC" >/dev/null
#
# File: $(basename "$DEFAULT_DROPIN_CONF_FILENAME")
# Path: $(dirname "$CHRONY_SOURCESD_DIRPATH")
# Title: 'pool' directives for Chrony sources file
# Creator: $(basename "$0")
# Date: $(date)
# Description:
#   These pool directives used to be in the main Chrony configuration file
#   (/etc/chrony/chrony.conf) but has been relocated to within this
#   sources.d subdirectory in form of this file.
#
DROPIN_EOF
for this_line in "${RELOCATE_POOL_DIRECTIVES_A[@]}"; do
  echo "Relocating '$this_line' into new drop-in file..."
  echo "${this_line}" >> "$DROPIN_SOURCE_FILESPEC"

  # Now replace corresponding line in chrony.conf with commented out line
  echo "Removing old 'pool' directive from main Chrony config file"
  sudo sed -r -i.backup \
     "s/^(\s*(~#)*\s*pool\s+.*)$/# former Debian NTP pool entry got relocated\n# to $DEFAULT_DROPIN_CONF_FILENAME/" \
     "${CHRONY_CONF_FILESPEC}"
  echo ""
done
echo "" >> $DROPIN_SOURCE_FILESPEC

echo "Reverifying syntax of configuration/sources files..."
# Verify the configuration files to be correct, syntax-wise.
chronyd -p -f "$CHRONY_CONF_FILESPEC" >/dev/null 2>&1
retsts=$?
if [ "$retsts" -ne 0 ]; then
  # rerun it but with verbosity
  chronyd -p -f "$CHRONY_CONF_FILESPEC"
  echo "ERROR: $CHRONY_CONF_FILESPEC failed syntax check."
  exit 13
fi
echo "$CHRONY_CONF_FILESPEC passes syntax-check"


exit
# DISABLE crappy systemd-timesyncd
stop_disable_sysd ntp
stop_disable_sysd time-daemon
stop_disable_sysd systemd-timesyncd.service

# sudo systemctl restart chrony.service
sudo chronyc reload sources
sleep 5
sudo chronyc sources
RETSTS=$?
if [ "$RETSTS" -ne 0 ]; then
  echo "Command 'chronyc source' has error code $RETSTS"
  echo "Executing 'systemctl status chrony.service'..."
  systemctl status chrony.service
  exit $RETSTS
fi

if [ "$CHRONY_DHCP_COUNT" -ge 1 ]; then
  echo "Cool. We detected your DHCP server is obtaining NTP address(es)."
fi


