#!/bin/bash
# File: 403-net-resolv-check.sh
# Title: Check out the /etc/resolv.conf to ensure that it is working
# Description:
#

RESOLV_CONF_FILESPEC="/etc/resolv.conf"

echo "This script tests the current state and integrity of "
echo "the $RESOLV_CONF_FILESPEC file."
echo ""

# What can we tell about /etc/resolv.conf file?
RESOLV_FILE_MODE='regular file'
RESOLV_SYMLINKED=
RESOLV_FILELINK=

if [ ! -e "$RESOLV_CONF_FILESPEC" ]; then
  echo "File $RESOLV_CONF_FILESPEC does not exist; aborted."
  exit 9
elif [ -h "$RESOLV_CONF_FILESPEC" ]; then
  RESOLV_SYMLINKED='yes'
  echo "Resolv.conf is a symlink file."
  REAL_RESOLV_CONF_FILESPEC="$(realpath -m "$RESOLV_CONF_FILESPEC")"
  echo "Resolv.conf is really located in $REAL_RESOLV_CONF_FILESPEC"
  # Determine if symlink belongs to systemd
  if [[ "$REAL_RESOLV_CONF_FILESPEC" = *systemd* ]]; then
    RESOLV_FILE_MODE='systemd-resolved (by symlink)'
    RESOLV_FILELINK='systemd-resolved'
  elif [[ "$REAL_RESOLV_CONF_FILESPEC" = *NetworkManager* ]]; then
    RESOLV_FILE_MODE='NetworkManager (by symlink)'
    RESOLV_FILELINK='NetworkManager'
  else
    RESOLV_FILE_MODE='a network manager, other than systemd or NetworkManager'
    RESOLV_FILELINK='other'
  fi
elif [ -f "$RESOLV_CONF_FILESPEC" ]; then
  RESOLV_SYMLINKED='no'
  echo "Resolv.conf is an ordinary file."
  if [ ! -r "$RESOLV_CONF_FILESPEC" ]; then
    echo "Resolv.conf is not a readable file; aborted"
    exit 9
  fi
  echo "Resolv.conf is a readable file."
  RESOLV_FILELINK='regular file'
  RESOLV_SYMLINKED='no'
else
  echo "File $RESOLV_CONF_FILESPEC is not a regular file "
  echo "   nor a symblink; aborted."
  exit 11
fi

# Determine which nameservers are currently existing... (regardless of
#     resolv.conf control)
# This can be done by recapturing the /etc/resolv.conf (however symlinked).
# Then tested using 'dig' to see if such DNS nameserver(s) is alive.
NAMESERVERS_LIST="$(grep '^\s*nameserver\s' /etc/resolv.conf | awk '{print $2}' | sort -u | xargs)"
if [ -z "$NAMESERVERS_LIST" ]; then
  echo "No nameservers found in /etc/resolv.conf"
  read -rp "Do you have a list of nameservers on hand? (N\y): " -eiN
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ -z "$REPLY" ] || [ "$REPLY" != 'y' ]; then
    echo "Aborted."
    exit 13
  fi
fi

# Check if nameservers are all alive and DNS-responsive
# If ordinary file, check if systemd-resolved is looking for a
# special nameserver 127.0.0.53 in /etc/resolv.conf
# It might be a hostname that maps to 127.0.0.53, so check there as well
VERIFIED_NAMESERVERS_LIST=
SYSTEMD_LOOPBACK_DNS_USED=
SYSTEMD_LOOPBACK_DNS_ACTIVE=
for this_ns in $NAMESERVERS_LIST; do
  found_nameserver_active=0
  found_systemd_loopback_dns=0
  NS_IP4_ADDR="$(getent ahostsv4 $this_ns | grep STREAM | awk '{print $1}')"
  # recursively look up on 127.0.0.53 (at a risk of going
  # outside of specified nameservers)
  if [ "$NS_IP4_ADDR" == "127.0.0.53" ]; then
    found_systemd_loopback_dns=1
    SYSTEMD_LOOPBACK_DNS_USED="yes"
  fi
  # Check if DNS server is running at this IP
  NS_ALIVE="$(dig +short +timeout=3 +tries=1 +norecurse @$this_ns localhost >/dev/null)"
  retsts=$?
  if [ "$retsts" -eq 9 ]; then
    found_nameserver_active=0
    echo "*DEAD* DNS nameserver ($this_ns) found in $RESOLV_CONF_FILESPEC."
    if [ "$found_systemd_loopback_dns" -eq 1 ]; then
      SYSTEMD_LOOPBACK_DNS_ACTIVE="no"
    fi
  # nameserver is alive
  elif [ "$retsts" -eq 0 ]; then
    found_nameserver_active=1
    if [ "$found_systemd_loopback_dns" -eq 1 ]; then
      SYSTEMD_LOOPBACK_DNS_ACTIVE="yes"
    fi
  fi
  echo "Active DNS nameserver found at $this_ns"
  VERIFIED_NAMESERVERS_LIST+="$this_ns "

  if [ "$found_systemd_loopback_dns" -eq 1 ]; then
    if [ "$found_nameserver_active" -eq 1 ]; then
      SYSTEMD_LOOPBACK_DNS_ACTIVE="yes"
      echo "Active DNS nameserver $this_ns is provided by systemd-resolved"
    else
      SYSTEMD_LOOPBACK_DNS_ACTIVE="no"
      echo "DEAD DNS nameserver $this_ns is provided by systemd-resolved"
    fi
  fi
done

echo ""
echo  "Resolv.conf is $RESOLV_FILE_MODE controlled."
if [ "$SYSTEMD_LOOPBACK_DNS_USED" == "yes" ]; then
  echo  "Resolv.conf is also using systemd 'nameserver 127.0.0.53'."
  if [ "$SYSTEMD_LOOPBACK_DNS_ACTIVE" == "no" ]; then
    echo  "   but systemd-resolved is not responding as a valid nameserver."
  fi
fi
echo ""
echo "Verified nameservers: $VERIFIED_NAMESERVERS_LIST"

echo ""
if [ "$SYSTEMD_LOOPBACK_DNS_USED" == "yes" ] &&
   [ "$SYSTEMD_LOOPBACK_DNS_ACTIVE" == "no" ]; then
  echo "This is weird; your 127.0.0.53 DNS server is dead,"
  if [ "$SYSD_RESOLVED_SVC_ACTIVE" == "active" ]; then
    echo "    yet systemd-resolved is active."
  else
    echo "    furthermore, systemd-resolved is not turned on."
  fi
  echo "ADVICE: Remove 'nameserver 127.0.0.53' from $RESOLV_CONF_FILESPEC file"
fi

SYSTEMCTL_BIN="$(whereis -b systemctl|awk -F: '{print $2}'|awk '{print $1}')"
if [ -n "$SYSTEMCTL_BIN" ]; then

  if [ "$SYSTEMD_LOOPBACK_DNS_ACTIVE" == "yes" ] || \
     [ "$RESOLV_FILE_MODE" != "regular file" ]; then


    # Obtain whether systemd-resolved is enabled/alive
    SYSD_RESOLVED_SVC_ENABLED="$(systemctl is-enabled systemd-resolved.service)"
    SYSD_RESOLVED_SVC_ACTIVE="$(systemctl is-active systemd-resolved.service)"

    # Obtain whether NetworkManager is enabled/alive
    SYSD_NETWORKMANAGER_SVC_ENABLED="$(systemctl is-enabled NetworkManager.service)"
    SYSD_NETWORKMANAGER_SVC_ACTIVE="$(systemctl is-active NetworkManager.service)"

    # Determine if we have to do anything
    if [ "$SYSD_RESOLVED_SVC_ENABLED" != "enabled" ] && \
       [ "$SYSD_RESOLVED_SVC_ACTIVE" != "active" ] && \
       [ "$SYSD_NETWORKMANAGER_SVC_ENABLED" != "enabled" ] && \
       [ "$SYSD_NETWORKMANAGER_SVC_ACTIVE" != "active" ]; then
      echo ""
      echo "This $RESOLV_CONF_FILESPEC is pretty static-y and stable."
      echo "Done."
      # NetworkManager may have already has its dropin config file
      # for disabling interaction with systemd
      exit 0
    fi
  fi
else
  echo "No systemd-resolved exist; systemd is not installed;"
  echo "This $RESOLV_CONF_FILESPEC is pretty static-y and stable."
  echo "Done."
  exit 0
fi

NETWORKMANAGER_BIN="$(whereis -b NetworkManager|awk -F: '{print $2}'|awk '{print $1}')"

# Pull all configs from NetworkManager
if [ -n "$NETWORKMANAGER_BIN" ]; then
  echo "Reading NetworkManager configurations..."
  TMPFILE=/tmp/junk
  # grep -E '^\s*pool' $CHRONY_CONF_FILESPEC > $TMPFILE
  $NETWORKMANAGER_BIN --print-config > $TMPFILE
  readarray -t  NM_CFG_A < $TMPFILE
  rm $TMPFILE

  if [ "${#NM_CFG_A[*]}" -eq 0 ]; then
    echo "No 'pool' directives found in NetworkManager configs. Aborted."
    exit 9
  fi
fi

# Find systemd-resolved

# This function is useful in extracting B from string "A B", "A B;" or "{ A B;".
function find_config_value
{
  local val
  echo "Scanning for key '$2' in section $1..."
  for this_line in "${NM_CFG_A[@]}"; do
    if [ -z "$this_line" ]; then
      continue
    fi
    # Skip comments
    COMMENT_LINE="$(echo $this_line | grep -E -- '^\s*#')"
    if [ -n "$COMMENT_LINE" ]; then
      continue
    fi
    # check section
    SECTION_LINE="$(echo $this_line | grep -E -- '^\s*\[\S+\]')"
    if [ -n "$SECTION_LINE" ]; then
      # our desired INI section?
      if [ "$SECTION_LINE" == "[${1}]" ]; then
        section_matched=1
      else
        section_matched=0
      fi
      continue
    fi
    if [ "$section_matched" -eq 1 ]; then
      # Is it our desired key?
      KEY_VALUE="$(echo $this_line | grep -E -- "^\s*${2}\s*=\s*\S"|awk -F= '{print $2}')"
      # did we find the value to the key?
      if [ -n "$KEY_VALUE" ]; then
        CONFIG_VALUE="$KEY_VALUE"
      fi
    fi
  done
  unset val
}

find_config_value "main" "systemd-resolved"
NETWORKMANAGER_INI_SYSTEMD_RESOLVED="$CONFIG_VALUE"

echo ""
echo "SUGGESTIONS"
echo "-----------"
# Concurrency of different resolver daemons
if [ -n "$NETWORKMANAGER_BIN" ] && [ -n "$SYSTEMCTL_BIN" ]; then
  # Both binaries exist

  # And its up and running, both resolver daemon
  if [ "$SYSD_NETWORKMANAGER_SVC_ACTIVE" == "active" ]; then
     [ "$SYSD_RESOLVED_SVC_ACTIVE" == "active" ] && \

    # Need to figure out WHO has precedence (systemd-resolved or NetworkManager)
    # did NetworkManager configure it right?
    # Does NetworkManager own the /etc/resolv.conf?
    if [ "$RESOLV_FILELINK" == "NetworkManager" ]; then

      if [ -z "$NETWORKMANAGER_INI_SYSTEMD_RESOLVED" ] || \
         [ "$NETWORKMANAGER_INI_SYSTEMD_RESOLVED" == "true" ]; then
        echo "NetworkManager config is missing the following:"
        echo "    [main]"
        echo "    systemd-resolved=false"
      else
        echo "NetworkManager controls /etc/resolv.conf"
        echo "Looks good."
      fi
    elif [ "$RESOLV_FILELINK" == "systemd-resolved" ]; then
      if [ -z "$NETWORKMANAGER_INI_SYSTEMD_RESOLVED" ] || \
         [ "$NETWORKMANAGER_INI_SYSTEMD_RESOLVED" == "false" ]; then
        echo "NetworkManager config is missing the following:"
        echo "    [main]"
        echo "    systemd-resolved=true"
      else
        echo "systemd-resolved controls /etc/resolv.conf"
        echo "Looks good."
      fi
    fi
  elif [ "$SYSD_RESOLVED_SVC_ENABLED" == "enabled" ] && \
   [ "$SYSD_NETWORKMANAGER_SVC_ENABLED" == "enabled" ]; then
    echo "Both systemd and NetworkManager are fighting over $RESOLV_CONF_FILESPEC"
  fi
fi
echo "Done."
exit 0

