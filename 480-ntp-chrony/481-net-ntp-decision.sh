#!/bin/bash -x
#
# INCOMPLETE:
#   Focus is on within the NTPD daemon (not Chrony)
#   Looks like it got supplanted by chrony
#
# INCOMPLETE:
# Usage:
#    481-net-ntp-choices.sh
#    ANNOTATION=1 481-net-ntp-choices.sh
# INCOMPLETE:
# Description:
#
# INCOMPLETE:
# * Must touch /run/ntp.conf.dhcp file (at bootup) in order to
#   obtain subsequential content of new_ntp_servers bash variable
#   during ISC dhclient RENEW|BOUND|REBIND|REBOOT

ANNOTATION=${ANNOTATION:-0}

function dump_ntpd_conf_current_settings
{
  echo "HAVE_RTC_DEVICE: $HAVE_RTC_DEVICE"
  echo "CMD_ACL_NEEDED: $CMD_ACL_NEEDED"
  idx=0
  while [ $idx -lt ${#NTPD_CONF_A[@]} ]; do
    echo "NTPD_CONF_A[$idx]: ${NTPD_CONF_A[$idx]}"
    ((idx+=1))
  done
}
function dump_ntpd_conf_mitm
{
  idx=0
  while [ $idx -lt ${#CC_MITM_A[@]} ]; do
    echo "CC_MITM_A[$idx]: ${CC_MITM_A[$idx]}"
    ((idx=idx+1))
  done
}
function dump_ntpd_conf_hwclk
{
  idx=0
  while [ $idx -lt ${#CC_HWCLK_A[@]} ]; do
    echo "CC_HWCLK_A[$idx]: ${CC_HWCLK_A[$idx]}"
    ((idx=idx+1))
  done
}
function dump_ntpd_conf_default_admin
{
  idx=0
  while [ $idx -lt ${#NTPD_CONF_A[@]} ]; do
    echo "NTPD_CONF_A[$idx]: ${NTPD_CONF_A[$idx]}"
    ((idx=idx+1))
  done
}

function dump_settings
{
  dump_ntpd_conf_current_settings
  dump_ntpd_conf_mitm
  dump_ntpd_conf_hwclk
  dump_ntpd_conf_default_admin
}

function annotate
{
  if [ "$ANNOTATION" -ne 0 ]; then
    NTPD_CONF_A+=("")
    NTPD_CONF_A+=("# $1")
  fi
}

# minimum settings of /etc/ntpd/ntpd.conf
NTPD_CONF_A=()
NTPD_CONF_A+=("pool pool.ntp.org iburst")
NTPD_CONF_A+=("driftfile /var/lib/ntpd/drift")
NTPD_CONF_A+=("makestep 1 3")
annotate "Set hardware clock after reading from its OS clock"
NTPD_CONF_A+=("rtcsync")

annotate "Set the default access for all NTP commands to 'nobody'"
# CMD_NET_ACL_NEEDED=0
NTPD_CONF_A+=("cmddeny all")  # This is the DEFAULT-DENY approach
dump_ntpd_conf_current_settings

# minimum setting to reduce impact of MitM NTP attacks
# TODO: do we need a minimum of 2 NTP servers for these settings?
CC_MITM_A=()
CC_MITM_A+=("server x.example.net iburst nts maxdelay 0.1")
CC_MITM_A+=("server y.example.net iburst nts maxdelay 0.2")
CC_MITM_A+=("server z.example.net iburst nts maxdelay 0.05")
annotate "Minimum number of NTP sources before the time is considered synced"
CC_MITM_A+=("minsources 3")
CC_MITM_A+=("maxchange 100 0 0")
CC_MITM_A+=("makestep 0.001 1")
CC_MITM_A+=("maxdrift 100")
CC_MITM_A+=("maxslewrate 100")
CC_MITM_A+=("driftfile /var/lib/ntpd/drift")
CC_MITM_A+=("ntsdumpdir /var/lib/ntpd")
annotate "Set hardware clock after reading from its OS clock"
CC_MITM_A+=("rtcsync")
dump_ntpd_conf_mitm

# Host Characteristics

# Does this host have a clock that may needs updating from an external
# time servers?
# Use to determine if there is any esoteric on-board hardware clock.
# Richard Stallman seems to maintain a good number of those.
if [ -f "/dev/rtc" ]; then
  HAVE_RTC_DEVICE=y
else
  HAVE_RTC_DEVICE=n
fi

CC_HWCLK_A=()
# Do you want to update the hardware clock on your host?
if [ "$HAVE_RTC_DEVICE" = 'y' ]; then
  CC_HWCLK_A+=("minsamples 32")
  CC_HWCLK_A+=("maxslewrate 500")
  CC_HWCLK_A+=("corrtimeratio 100")
  CC_HWCLK_A+=("maxdrift 500")
  CC_HWCLK_A+=("makestep 0.128 -1")
  CC_HWCLK_A+=("maxchange  1000 1 1")
  CC_HWCLK_A+=("maxclockerror 15")
fi
dump_ntpd_conf_hwclk

# End-User Security

# Allow access to NTP admin commands
echo ""
echo "ADMINISTRATION for ADMINISTRATORS of NTP"
echo "========================================"
echo "There are two complimentary sets of access method for "
echo "the NTPd administrators:"
echo ""
echo "  * file permission by user/Group ID (UNIX passwd/group)"
echo "  * communication pathway access (UNIX-socket/IP-network)"
echo ""
read -rp "Allow any NTP admin commands (security-risk) (N/y): " -eiN
REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
if [ "$REPLY" != 'y' ]; then

  # COMM_NET_REMOTE_NEEDED=0
  echo "...No remote access to ntpdd daemon netdev."

  COMM_NET_LOOPBACK_NEEDED=0
  echo "...No loopback access to ntpdd daemon netdev."

  # Turn off network port
#   CMD_NET_ACL_NEEDED=0
  # Usually we say 'cmddeny all' here, but this here is DEFAULT-DENY approach

  # Turn off UNIX socket
  CMD_UNIX_FPERM_NEEDED=0
  echo "...No UNIX file permission access to ntpdd daemon UNIX socket."

  # Do we warn admin that 'root' will also be affected here?
  echo ""
  echo "Next question will not affect NTP operation; just the admin part."
  echo "Useful if you want more security (less attackable surface area)."
  read -rp "but do allow root to use NTP admin commands (it's ok) Y/n: " -eiY
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ "$REPLY" != 'y' ]; then
    echo "...Disables UNIX socket to ntpdd daemon, even for root."
    NTPD_CONF_A+=("cmdport 0")  # disables UNIX socket, even for 'root'
  fi

else

  echo "...Open UNIX socket for NTPd administrators."
  # COMM_NET_REMOTE_NEEDED=1

  echo ""
  echo "For non-root users, there are several orthogonal layerings of "
  echo "communicaton-based ACLs:"
  echo ""
  echo "     Connection       Internet    Local Machine"
  echo "     Method           Subnet-ACL  User/Group-ACL"
  echo "     ---------------  ----------  --------------"
  echo "  1. UNIX socket      n/a         selectable"
  echo "  2. loopback access  127.0.0.1   any"
  echo "  3. remote access    selectable  n/a"
  echo ""
  echo "Lowest number is most secured. You can have a combo of 2 and 3."
  echo "Most problematic security is the use of option 2, loopback access."
  echo "Loopback is an open port to any local user and allows to do NTP "
  echo "admin (despite user's file permissions to 'ntpdc' tool)."

  # first ask about that access to the loopback netdev before file permission or
  # network ACL.  It's intricated security layering.
  #  Any non-root user - open up the loopback (and UNIX socket)
  #  Some user - security-warning
  #  no non-root user - close the loopback

  # Start by asking defensive questions on loopback interface
  echo ""
  echo "Sometimes, apps and scripts need access to NTP admin."
  echo "Nearly all of the time, 'ntpdc' can do this over UNIX socket."
  echo "There may be some NTP-oriented binary apps that requires"
  echo "loopback (lo) or 127.0.0.1 network connectivity to talk"
  echo "differently and directly to the NTP daemon (not many apps)."
  echo "It is very common to say 'no' here."
  read -rp "Must we allow apps/daemons to do NTP admin commands over loopback?  (N/y):" -eiN
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ "$REPLY" != 'y' ]; then
    COMM_NET_LOOPBACK_NEEDED=n
    # OK!  That makes things a bit easier
    # (we still ask questions about remote access, which may or may not be
    # encrypted)
    echo "...Deny 127.0.0.1 access to ntpdd daemon."
    NTPD_CONF_A+=("cmddeny 127.0.0.1")  # local-only
    # USER_VIA_LOOPBACK='none'
  else
    # Since the loopback is wide open, we don't care to set up
    # for the UNIX file permissions approach for the 'ntpdc' tool.
    COMM_NET_LOOPBACK_NEEDED=y
    echo "...Allow 127.0.0.1 access to ntpdd daemon."
    NTPD_CONF_A+=("cmdallow 127.0.0.1")  # local-only
    # USER_VIA_LOOPBACK='any'
  fi

  if [ "$COMM_NET_LOOPBACK_NEEDED" != "y" ]; then
    echo "...No need to set up user/group permission for 'ntpdc' tool."
    echo "...Loopback is wide open for any user to use 'ntpdc'."
  else
    # Ahhh, security clampdown is still in progress at this point.
    # Ask about user/group file permissions for 'ntpdc' tool.
    echo "...Ask about user/group file permissions for 'ntpdc' tool."
  fi


  # Allow access to NTP admin commands by ntpd daemon UNIX socket?

  # First, ask questions about UNIX file permission as an access method

  # Do you allow users with ntpd group, or just only root
  # to use the admin tool to NTPd daemon;
  # there is no 'everybody' option here.
  # the tool is named NTPd CLI (ntpdc) utility.
  #  root-only   'cmdport 0'  # turns off UNIX socket
  #  root-only   'cmddeny all' # turns off network access
  #  ntpd-group (leave cmdport and cmddeny alone)
  echo ""
  echo "As a bare minimum, only root can do NTP admin commands"
  echo "   and only over UNIX socket (not by netdev/network)."
  read -rp "Allow user(s) to do NTP admin commands without su/sudo? (N/y): " -eiN
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ "$REPLY" = 'y' ]; then
    CMD_UNIX_FPERM_NEEDED=1
    echo "...No UNIX file permissions needed."
  else

    CMD_UNIX_FPERM_NEEDED=0
    echo "...UNIX file permissions needed."
  fi
  echo ""
  echo "Communication Pathway Access for NTP admin"
  echo "------------------------------------------"
  echo "Basic access settings by:"
  echo "  * UNIX-socket - most-secured, no remote access"
  echo "  * localhost(127.0.0.1) - no remote access, default setting"
  echo "  * network-accessible - no security"
  echo "  * network-accessible, encrypted - highest security"
  echo ""


  echo "Sending NTP admin commands over network is a security-risk."
  echo "Windows and default macOS do not support NTP Encryption."


  read -rp "NTP Admin commands are to be accepted over IP network (N/y): " -eiN
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ "$REPLY" != 'y' ]; then

#     CMD_NET_ACL_NEEDED=0
    # Strictly UNIX socket are only used for NTP admin commands.
    # Turn off network port
    echo "...Only for NTP admin commands, turning off that network port 323..."
    NTPD_CONF_A+=("cmddeny all")
  else

    # CMD_NET_ACL_NEEDED=1
    # There be some NTP admin commands going over networking
    echo "...Turning ON network port 323 for NTP admin commands..."
    NTPD_CONF_A+=("cmdport 323")
  fi  # allow admin cmds over IP network?

  # Allow access to NTP admin commands by ntpd daemon UNIX socket?
  # We ALWAYS expect the Unix sockets to be opened, bare minimum default

fi  # allow any admin cmds?

if [ "$CMD_UNIX_FPERM_NEEDED" -ne 0 ]; then
  echo ""
  echo "NTPd enforces 'ntpd' group privilege to allow admin tool usage."
  echo "No 'ntpd' supplemental group; no admin access."
  echo "To start with, only 'root' user has ntpd privilege."
  echo "This is done by adding 'ntpd' group to each non-root user as needed."
  read -rp "  Is root priv. good enough for all serious ntpd administraton? (Y/n): " -eiY
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  ADD_GROUP_SUPP=()
  if [ "$REPLY" = 'Y' ]; then
    # for now, only add one to a list, then do the work at the end.
    read -rp "Enter in user name to have this 'ntpd' group privilege: "
    ADD_GROUP_SUPP+=("$REPLY")
  fi
  read -rp "  * Give non-root users a network access to ntpdc? (n/Y): "
  read -rp "  * Give local users access by Unix socket?"
  read -rp "Give network access to NTP admin for remote users? (N/y): "
  read -rp "Give UNIX socket-only access to NTP admins for local users? (N/y): "
fi
dump_ntpd_conf_current_settings
exit 0

# All done with the administrator/administration part of NTP

# Moving on to the NTP protocol aspects

# Do you want to use encryption NTP only?
if [ "$NET_REMOTE_NEEDED" -ge 1 ]; then
  echo ""
  echo "Encryption is great protection against attackers.  Only useful if you"
  echo "actually own an Atomic Clock or GPS time-provider."
  echo "Also useful if ALL clients make use of newer NTPsec protocol."
  echo "No Windows support this."
  echo "No Linux using systemd-timesyncd support this."
  echo "macBook can be made to support this via 'brew install ntpd' cmd."
  echo "Just say 'no' otherwise."
fi


# Do you have any apps that requires ultra-precision timekeeping
# something on the order of 0.0000001 second? Finance trading?

# Does your firewall block NTP packets yet provides NTP
# time servers?

# Do you know who the upstream NTP servers that you can use are?
#  (pool or server)

# Do you know what kind of NTP server they are using?  x
#   if ntpdd, then use 'xleave', 'smoothtime', 'leapsecmode' option
#   if Windows, then insert 'maxdistance 16.0'
#   if ntp, no change

# Are all your local LAN clients using these servers?

# Single Ethernet port?

# Is this host a desktop without containers/LXC/QEMU/Dockers?
#   Might automatically decide by detecting for static IP netdev interfaces

# Can we get the DHCP client new_ntp_addresses?
#

# Detect multiple netdev interfaces

# Prompt for time-support server on each netdev interfaces
# (recommends no time-support on Wireguard netdev, yes on bridges)
#    'allow 192.168.1.0/24' for eth0 to serve time

