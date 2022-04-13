#!/bin/bash
# File: 484-net-ntp-chrony-admin.sh
# Title: Which administrator can use Chrony CLI utility?
# Description:
#   - Checks distro, selects username/groupname set
#   - Ask a bunch of questions
#     - anyone an admin?
#     - anyone a chrony admin?
#     - anyone needs network access as an admin?
#   - examine current host for active netdev interfaces
#
# Coding Design
#   Makes use of tri-state Bash variable (undefined/false/true)
#
# Reads:  nothing
# Modifies:  nothing
# Adds:
#   /etc/chrony/conf.d/20-chronyc_cli_admin_access.conf
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

readonly FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-settings-chrony-admin.sh"

flex_ckdir "$ETC_DIRSPEC"
flex_ckdir "$VAR_DIRSPEC"
flex_ckdir "$extended_sysconfdir"

DROP_IN_CONF_FILENAME="20-chronyc_cli_admin_access.conf"

# Auto determine username of Chrony by passwd probes

USERNAMES_LIST="_chrony chrony ntp"  # new Chrony

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

flex_ckdir "$CHRONY_RUN_DIRSPEC"
flex_ckdir "$CHRONY_VAR_LIB_DIRSPEC"



# DEFAULT_CHRONY_CONF_FILENAME="chrony.conf"
# DEFAULT_CHRONY_DRIFT_FILENAME="chrony.drift"
DEFAULT_CHRONY_SOCK_FILENAME="chrony.sock"

CHRONY_RUN_DIR="$runstatedir/$package_name"  # /run/chrony
# CHRONY_VAR_LIB_DIR="$varlibdir/$package_name"

CHRONY_CONFD_DIR="$extended_sysconfdir/conf.d"  # /etc/chrony/conf.d
# CHRONY_SOURCESD_DIR="$extended_sysconfdir/sources.d"  # /etc/chrony/sources.d
# CHRONY_LOG_DIR="$LOG_DIRSPEC/chrony"  # /var/log/chrony
# CHRONY_DRIFT_FILESPEC="$CHRONY_VAR_LIB_DIR/$DEFAULT_CHRONY_DRIFT_FILENAME"
# CHRONY_KEYS_FILESPEC="$extended_sysconfdir/chrony.keys"
CHRONY_SOCK_FILESPEC="$CHRONY_RUN_DIR/$DEFAULT_CHRONY_SOCK_FILENAME"

echo "final configure/autogen/autoreconf settings:"
echo "  prefix:        $prefix"
echo "  sysconfdir:    $sysconfdir"
echo "  LOCALSTATEDIR: $localstatedir"
echo "  RUNDIR: $rundir or $runstatedir"
#
ANNOTATE=${ANNOTATE:-y}
DEFAULT_CMD_PORT=323

CHRONYD_BIN="$(whereis -b chronyd | awk '{print $2}')"
if [ -z "$CHRONYD_BIN" ]; then
  echo "$CHRONYD_BIN is not found; aborted."
  exit 1
fi

HAVE_IPV4=${HAVE_IPV4:-1}
# Verify IPv6 presence
if [ -d /proc/sys/net/ipv6 ]; then
  echo "Auto-detected IPv6 support; enabling IPv6"
  HAVE_IPV6=${HAVE_IPV6:-1}
else
  HAVE_IPV6=0
fi

if [[ -z "$BUILDROOT" ]] || [[ "$BUILDROOT" == '/' ]]; then
  SUDO_BIN=sudo
  echo "Writing ALL files as 'root'..."
else
  echo "Writing ALL files into $BUILDROOT as user '$USER')..."
fi

function check_undefined
{
  var_name=$1
  if [ ! -v "$var_name" ]; then
    echo "Variable $var_name is undefined" ;
    exit 254
  elif [ -z "$var_name" ]; then
    echo "No argument given"
    exit 254
  else
    value=${!var_name}
    if [ -z "$value" ]; then
      echo "No value given" ; exit 253
    else
      echo "value of $1 is: $value"
    fi
  fi
}

# Syntax: create_file file-permission owner:group
function create_file
{
  local dir_name
  dir_name="$(dirname "$FILESPEC")"
  if [ -z "$SUDO_BIN" ]; then
    if [ ! -d "$dir_name" ]; then
      mkdir -p "$dir_name"
      echo "Creating $dir_name directory..."
    fi
  fi
  [[ -n "$SUDO_BIN" ]] && flex_touch "$FILESPEC"
  [[ -n "$SUDO_BIN" ]] && flex_chmod "$1" "$FILESPEC"
  [[ -n "$SUDO_BIN" ]] && flex_chown "$2" "$FILESPEC"
  cat << CREATE_FILE_EOF | $SUDO_BIN tee "${BUILDROOT}${CHROOT}$FILESPEC" >/dev/null
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
}

function write_conf
{
  cat << WRITE_CONF_EOF | $SUDO_BIN tee -a "${BUILDROOT}${CHROOT}$FILESPEC" >/dev/null
$1
WRITE_CONF_EOF
}

function write_note
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << WRITE_NOTE_EOF | $SUDO_BIN tee -a "${BUILDROOT}${CHROOT}$FILESPEC" >/dev/null
$1
WRITE_NOTE_EOF
  fi
}

function write_note_bindcmdaddress
{
  if [ "$ANNOTATE" = "y" ]; then
    cat << CHRONY_DROPIN_CONF_EOF | $SUDO_BIN tee -a "${BUILDROOT}${CHROOT}$FILESPEC" >/dev/null
# Command and monitoring access
#   bindcmdaddress address
#     The bindcmdaddress directive specifies a local IP address to which
#     chronyd will bind the UDP socket listening for monitoring command
#     packets (issued by chronyc). On systems other than Linux, the
#     address of the interface needs to be already configured when
#     chronyd is started.
#
#     This directive can also change the path of the Unix domain command
#     socket, which is used by chronyc to send configuration commands.
#     The socket must be in a directory that is accessible only by the
#     root or chrony user. The directory will be created on start if it
#     does not exist. The compiled-in default path of the socket is
#     /run/chrony/chronyd.sock. The socket can be disabled by setting the
#     path to /.
#
#     By default, chronyd binds the UDP sockets to the addresses
#     127.0.0.1 and ::1 (i.e. the loopback interface). This blocks all
#     access except from localhost. To listen for command packets on all
#     interfaces, you can add the lines:
#
#     bindcmdaddress 0.0.0.0
#     bindcmdaddress ::
#
#     to the configuration file.
#
#     For each of the IPv4, IPv6, and Unix domain protocols, only one
#     bindcmdaddress directive can be specified.
#
#     An example that sets the path of the Unix domain command socket is:
#
#     bindcmdaddress /var/run/chrony/chronyd.sock
#
#
# Disable UNIX socket used for Chrony (chronyc) CLI control access
#
CHRONY_DROPIN_CONF_EOF
  fi
}

function write_note_cmdallow
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << CHRONY_DROPIN_CONF_EOF | $SUDO_BIN tee -a "${BUILDROOT}${CHROOT}$FILESPEC" >/dev/null
#   cmdallow [all] [subnet]
#     This is similar to the allow directive, except that it allows
#     monitoring access (rather than NTP client access) to a particular
#     subnet or host. (By ‘monitoring access’ is meant that chronyc can
#     be run on those hosts and retrieve monitoring data from chronyd on
#     this computer.)
#
#     The syntax is identical to the allow directive.
#
#     There is also a cmdallow all directive with similar behaviour to
#     the allow all directive (but applying to monitoring access in this
#     case, of course).
#
#     Note that chronyd has to be configured with the bindcmdaddress
#     directive to not listen only on the loopback interface to actually
#     allow remote access.
CHRONY_DROPIN_CONF_EOF
  fi
}

function write_note_cmddeny
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << CHRONY_DROPIN_CONF_EOF | $SUDO_BIN tee -a "${BUILDROOT}${CHROOT}$FILESPEC" >/dev/null
#   cmddeny [all] [subnet]
#     This is similar to the cmdallow directive, except that it denies
#     monitoring access to a particular subnet or host, rather than
#     allowing it.
#
#     The syntax is identical.
#
#     There is also a cmddeny all directive with similar behaviour to the
#     cmdallow all directive.
CHRONY_DROPIN_CONF_EOF
  fi
}

function write_note_cmdport
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << CHRONY_DROPIN_CONF_EOF | $SUDO_BIN tee -a "${BUILDROOT}${CHROOT}$FILESPEC" >/dev/null
# cmdport port
#   The cmdport directive allows the port that is used for run-time
#   monitoring (via the chronyc program) to be altered from its default
#   (323). If set to 0, chronyd will not open the port, this is useful
#   to disable chronyc access from the Internet. (It does not disable
#   the Unix domain command socket.)
#
#   An example shows the syntax:
#
#       cmdport 257
#
#   This would make chronyd use UDP 257 as its command port. (chronyc
#   would need to be run with the -p 257 switch to inter-operate
#   correctly.)
#
CHRONY_DROPIN_CONF_EOF
  fi
}

function dump_chrony_flags
{
  echo "FILESPEC: $FILESPEC"
  echo "NEED_CMD_ACL_UNIX_SOCKET: $NEED_CMD_ACL_UNIX_SOCKET"
  echo "NEED_GROUP_SUPP_FOR_USERS: $NEED_GROUP_SUPP_FOR_USERS"
  echo "NEED_CMD_PORT_OPEN: $NEED_CMD_PORT_OPEN"
  echo "NEED_CMD_ACL_NET_LOOPBACK: $NEED_CMD_ACL_NET_LOOPBACK"
  echo "NEED_CMD_ACL_NET_REMOTE: $NEED_CMD_ACL_NET_REMOTE"
  read -rp "DEBUG: press any key to continue: " -n1
}

# Begin of End-User Administration Rights

# Allow access to NTP admin commands
echo ""
echo "ADMINISTRATION RIGHTS for Chrony"
echo "================================"
echo "There are two complimentary sets of access method for "
echo "the Chrony administrators:"
echo ""
echo "  * file permission by user/Group ID (UNIX passwd/group)"
echo "  * communication pathway access (UNIX-socket/IP-network)"
echo ""
echo "GENERAL QUESTION"
echo "----------------"
echo ""
echo "As a default, only root user has administrative-rights to NTP commands."
read -rp "Accept admin commands from non-root user or by network access (N/y): " -eiN
REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
if [ "$REPLY" != 'y' ]; then

  # Turn off network port; what we have left are root-user and UNIX socket
  echo "...Closing command access to remote network."
  NEED_CMD_ACL_NET_REMOTE=0
  echo "...Closing command access to loopback (local) network."
  NEED_CMD_ACL_NET_LOOPBACK=0
  echo "...Closing network port."
  NEED_CMD_PORT_OPEN=0
  echo "...Do not allow '$GROUPNAME' group to access UNIX socket file."
  NEED_GROUP_SUPP_FOR_USERS=0

  # Do we warn admin that 'root' will also be affected here?  (Nah, alrighty)
  echo ""
  echo "Next question will not affect NTP operation; just the admin commands."
  echo "Useful if you want more security (less attackable surface area)."
  read -rp "But do allow root to use NTP admin commands (it's ok) Y/n: " -eiY
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ "$REPLY" != 'y' ]; then
    echo "...Forcibly disables UNIX socket to chronyd daemon, even for root."
    NEED_CMD_ACL_UNIX_SOCKET=0
  else
    echo "...Keeping UNIX socket open to chronyd daemon, but root as a minimum."
    NEED_CMD_ACL_UNIX_SOCKET=1
    # Leave NEED_GROUP_SUPP_FOR_USERS for later (non-root user inquiry)
  fi

else
  echo "...Bare minimum, UNIX socket is open for NTP CLI usage for root only."
  NEED_CMD_ACL_UNIX_SOCKET=1
fi

############################################################
# Allow access to loopback network (lo) interface
############################################################

if [ -z "$NEED_CMD_ACL_NET_LOOPBACK" ]; then
  echo ""
  echo "For non-root and network users, Chrony daemon has several orthogonal "
  echo "layerings of communication-based ACLs to its command ports:"
  echo ""
  echo "     Command Port     Internet    Local Machine"
  echo "     Connection Type  Subnet-ACL  User/Group-ACL"
  echo "     ---------------  ----------  --------------"
  echo "  0. none             n/a         n/a"
  echo "  1. UNIX socket      n/a         selectable"
  echo "  2. loopback access  127.0.0.1   any"
  echo "  3. remote access    selectable  n/a"
  echo ""
  echo "Lowest number is most secured. You can have a combo of 2 and 3."
  echo "Most problematic security is the use of option 2, loopback access."
  echo "Loopback is an open port to any local user and allows to do NTP "
  echo "admin (despite user's file permissions to 'chronyc' tool)."
  read -rp "Press any key to continue: " -n1


  echo ""
  echo "'chronyc' CLI tool is currently able to admin NTP thru a UNIX socket."
  echo "Its UNIX socket is group-owned by '$GROUPNAME'."
  echo ""
  echo "Use of 'chronyc' CLI can be restricted to selected user(s) "
  echo "by '$GROUPNAME' group file permission."
  echo "User(s) can gain '$GROUPNAME' file permission access with this command:"
  echo "    sudo usermod -a -G $GROUPNAME <username>"
  echo ""
  echo "Rarely do other apps and scripts also need to admin NTP."
  echo "Chrony daemon are entirely controlled by 'chronyc' CLI tool."
  echo ""
  echo "There may be some Chrony-related script that requires a "
  echo "loopback (lo) or 127.0.0.1 network connection to talk"
  echo "differently and directly with the NTP daemon."
  echo "But these same script can use UNIX socket instead for better security."
  echo ""
  echo "It is very common to say 'no' here."
  read -rp "For admin commands, must we allow any OTHER apps to use loopback?  (N/y):" -eiN
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ "$REPLY" != 'y' ]; then

    echo "...Deny 127.0.0.1 access to chronyd daemon as well"
    NEED_CMD_ACL_NET_LOOPBACK=0
    echo "...By implicit default, closing port $DEFAULT_CHRONY_PORT/udp."
    NEED_CMD_PORT_OPEN=0
  else
    # Since the loopback is wide-wide open, we can abandon UNIX socket.
    echo "...Turn on network port $DEFAULT_CHRONY_PORT/udp."
    NEED_CMD_PORT_OPEN=1  # loopback network port is needed firstly, force open
    echo "...Allow 127.0.0.1 access to chronyd daemon."
    NEED_CMD_ACL_NET_LOOPBACK=1
    # No need to use the UNIX file permission approach for 'chronyc' tool.
    echo "...By default, no group supplemental permission for UNIX socket needed."
    NEED_GROUP_SUPP_FOR_USERS=0  # UNIX socket file permission 'unneeded'
  fi

  if [ -z "$NEED_GROUP_SUPP_FOR_USERS" ]; then
    # Allow access to NTP admin commands by chrony daemon UNIX socket?

    # First, ask questions about UNIX file permission as an access method

    # Do you allow users with chrony group, or just only root
    # to use the admin tool to Chrony daemon;
    # there is no 'everybody' option here.
    # the tool is named Chrony CLI (chronyc) utility.
    #  root-only   'bindacqdevice /'  # turns off UNIX socket
    #  root-only   'cmddeny all' # turns off network access
    #  chrony-group (leave cmdport and cmddeny alone)
    echo ""
    echo "Chrony enforces 'chrony' group privilege to allow admin tool usage."
    echo "No 'chrony' supplemental group; no admin access."
    echo "To start with, only 'root' user has chrony privilege."
    echo "This is done by adding 'chrony' group to each non-root user as needed."
    echo "As a bare minimum, only root can do NTP admin commands"
    if [ "$NEED_CMD_ACL_NET_LOOPBACK" -eq 0 ]; then
      echo "   and only over UNIX socket (not by netdev/network)."
    else
      echo "   and only over loopback network interface."
    fi
    echo "Is root priv. or sudo good enough for its chrony administraton?"
    read -rp "Allow LOCAL user(s) to do NTP admin commands without su/sudo? (N/y): " -eiN
    REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
    if [ "$REPLY" = 'y' ]; then
      NEED_GROUP_SUPP_FOR_USERS=1
    else
      NEED_GROUP_SUPP_FOR_USERS=0
    fi
  fi

  if [ -z "$NEED_CMD_ACL_NET_REMOTE" ]; then
    echo ""
    echo "Communication Pathway Access for NTP admin"
    echo "------------------------------------------"
    echo "Available current settings (so far) are:"
    if [ "$NEED_CMD_ACL_UNIX_SOCKET" -ge 1 ]; then
      echo " * UNIX-socket -          access PERMITTED to '$GROUPNAME' group"
    else
      echo " * UNIX-socket -          access disabled"
    fi
    if [ "$NEED_CMD_ACL_NET_LOOPBACK" -ge 1 ]; then
      echo " * localhost(127.0.0.1) - access PERMITTED"
    else
      echo " * localhost(127.0.0.1) - access disabled"
    fi
    echo ""
    echo "Allowing NTP admin commands over network is in itself a security-risk."
    read -rp "Accept NTP admin commands over IP network (N/y): " -eiN
    REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
    if [ "$REPLY" = 'y' ]; then

      # Port might be open before by loopback but open them again ... anyway
      echo "...Turning ON port $DEFAULT_CMD_PORT/udp for remote NTP admin commands..."
      NEED_CMD_PORT_OPEN=1
      echo "...Enabling remote access via $DEFAULT_CMD_PORT/udp for NTP admin commands."
      NEED_CMD_ACL_NET_REMOTE=1
    else
      NEED_CMD_ACL_NET_REMOTE=0
    fi  # allow admin cmds over IP network?

  fi  # access control list for non-root or remote network
fi

check_undefined NEED_CMD_ACL_NET_REMOTE
check_undefined NEED_CMD_ACL_NET_LOOPBACK
check_undefined NEED_CMD_ACL_UNIX_SOCKET
check_undefined NEED_CMD_PORT_OPEN
check_undefined NEED_GROUP_SUPP_FOR_USERS

# Prompt for allowed netdev interfaces
ROUTE_INTF="$(ip -o -f inet route list default | awk '{print $5}')"
#  Can only bind to interfaces if a default gateway exist
if [ "$NEED_CMD_ACL_NET_LOOPBACK" -ge 1 ] || { \
       [ -n "$ROUTE_INTF" ] &&
       [ "$NEED_CMD_ACL_NET_REMOTE" -ge 1 ];
     }; then
  echo "Here's a list of network interfaces on this machine"
  echo "that Chronyd daemon can listen for NTP commands on:"
  ip -o -brief addr show
  echo "Daemon can only bind to one network interface or all "
  echo "network interfaces for receiving NTP admin commands."
  echo ""
  echo "BUG:  BINDCMDADDRESS and NETDEV do not go together"
  exit 1
  OPT_BINDCMDADDRESS_NETDEV=
  if [ "$NEED_CMD_ACL_NET_REMOTE" -ge 1 ]; then
    read -rp "Listen to all interfaces? (Y/n): " -eiY
    REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
    if [ "$REPLY" != 'y' ]; then
      # find interface of default route
      echo ""
      read -rp "Which interface to bind to for NTP commands?: " -ei"$ROUTE_INTF"
      OPT_BINDCMDADDRESS_NETDEV="$REPLY"
    fi
  elif [ "$NEED_CMD_ACL_NET_LOOPBACK" -ge 1 ]; then
    # shellcheck disable=SC2034
    OPT_BINDCMDADDRESS_NETDEV=lo
  fi
fi

# Prompt for allowed subnets
DEFAULT_SUBNET="0.0.0.0/0"
CAPTURED_SUBNET=""
if [ "$NEED_CMD_ACL_NET_REMOTE" -ge 1 ]; then
  while [ -n "$REPLY" ]; do
    echo ""
    echo "All subnet is 0.0.0.0/0"
    echo "Enter in subnet as 123.123.123.123/24 or press ENTER to exit"
    read -rp "Enter in remote subnet to allow incoming remote commands: " \
      -ei"$DEFAULT_SUBNET"
    if [ -n "$REPLY" ]; then
      CAPTURED_SUBNET="$CAPTURED_SUBNET $REPLY"
    else
      break
    fi
  done
fi

USER_PRIV_LIST=""
# Prompt for user to have 'chrony' group added to their group supplementals
if [ "$NEED_GROUP_SUPP_FOR_USERS" -ge 1 ]; then
  # Prompt for user's username that is to gain chrony group privilege
  echo ""
  REPLY="(keep going)"
  PROMPT_USER="$USER"
  while [ -n "$REPLY" ]; do
    echo "Enter in username to gain this '$GROUPNAME' group privilege."
    if [ -n "$PROMPT_USER" ]; then
      PROMPT="Username ([$PROMPT_USER]): "
    else
      PROMPT="Username: "
    fi
# shellcheck disable=SC2086 disable=SC2229
    read -rp "$PROMPT" -e ${PROMPT_USER}
    if [ -z "$REPLY" ]; then
      break
    else
      FOUND_USER="$(grep "$REPLY" /etc/passwd | awk -F: '{print $1}')"
      if [ -z "$FOUND_USER" ]; then
        echo "Username '$REPLY' is not found in system login; try again."
        continue
      fi
      USER_PRIV_LIST="$USER_PRIV_LIST $REPLY"
      PROMPT_USER=
    fi
  done
fi

############### SECURITY ###############
if [ "$NEED_GROUP_SUPP_FOR_USERS" -ge 1 ] && \
     {
       [ "$NEED_CMD_ACL_NET_REMOTE" -ge 1 ] || \
       [ "$NEED_CMD_ACL_NET_LOOPBACK" -ge 1 ] \
     ;}; \
   then
  echo ""
  echo "SECURITY WARNING:"
  echo "You're enforcing file permission on UNIX-socket for only a few users."
  echo "Yet, you've opened to accept any network connections from anyone."
  echo "May want to re-evaluate your security stance."
  read -rp "Press any key to continue" -n1
fi

if [ "$NEED_CMD_ACL_NET_LOOPBACK" -eq 0 ] && \
   [ "$NEED_CMD_ACL_NET_REMOTE" -eq 1 ]; then
  echo ""
  echo "SECURITY WARNING:"
  echo "You've asked for accepting ALL incoming network for remote commands."
  echo "Yet, you've denied any for local loopback connections for remote
commands."
  echo "It is a rare-breed of network security setup.  You sure you want this?"
  read -rp "Press any key to continue" -n1
#
# Reads:
# Modifies:
# Adds:
fi

#################################################
# All done with querying of user-input on about
# the administrator/administration part of NTP
#################################################

FILENAME="$DROP_IN_CONF_FILENAME"
FILEPATH="$CHRONY_CONFD_DIR"
FILESPEC="$FILEPATH/$FILENAME"

echo ""
echo "Creating $FILESPEC file..."
if [ -n "$SUDO_BIN" ]; then
  read -rp "Press any key to perform sudo operations (Ctrl-C to abort): " -n 1
fi

create_file 0640 "${USERNAME}:${GROUPNAME}" \
    "NTP Command Access for Chrony (chronyc) CLI client utiliy"

# Work on 'cmdport'/cmdallow
write_note_cmdport
if [ "$NEED_CMD_ACL_NET_REMOTE" -ne 0 ] || \
   [ "$NEED_CMD_ACL_NET_LOOPBACK" -ne 0 ] ; then
  write_note "# Endable network-based communication to command port"
  write_conf "cmdport $DEFAULT_CMD_PORT"
  echo "TODO: Add remote ACL directives (cmdallow)"
  write_note_cmdallow
  write_conf "cmdallow all"  # TODO: Narrow this down
  write_note ""
else
  write_note "# Disable network-based communication to command port"
  write_conf "cmdport 0"
  write_note ""
fi
# Done with 'cmdport'


# Focus on 'bindcmdaddress' firstly.
# Check if bindcmdaddress directive is needed
if [ -n "$NEED_CMD_ACL_UNIX_SOCKET" ]; then
  write_note_bindcmdaddress
  if [ "$NEED_CMD_ACL_UNIX_SOCKET" -eq 0 ]; then
    echo "...No UNIX file permissions needed."
    write_conf "bindcmdaddress /"
    write_note ""
  else
    echo "...UNIX file permissions needed for chronyc UNIX socket access."
    echo "...Start adding '_chrony' group supplemental to selected user/UID"
    write_note "# UNIX file permissions needed for chronyc UNIX socket access."
    write_conf "bindcmddevice $CHRONY_SOCK_FILESPEC"
    write_note ""
  fi
fi
if [ -n "$NEED_CMD_ACL_NET_REMOTE" ] || \
   [ -n "$NEED_CMD_ACL_NET_LOOPBACK" ]; then
  # Loopback and Network are intertwined so if-else-nest these selections
  if [ "$NEED_CMD_ACL_NET_LOOPBACK" -ge 1 ]; then
    echo "...No need to set up user/group permission for 'chronyc' tool."
    echo "...Loopback is wide open for any user to use 'chronyc'."
    CMDDENY_ALL=1
    if [ "$HAVE_IPV4" -ne 0 ]; then
      write_note "# Open IPv4 loopback network port for command access with Chrony (chronyc) CLI."
      write_conf "bindcmdaddress 127.0.0.1"
      write_note ""
      CMDDENY_LOOPBACK_LIST="127.0.0.1"
    fi

    if [ "$HAVE_IPV6" -ne 0 ]; then
      write_conf ""
      write_note "# Open IPv6 loopback network port for command access with Chrony (chronyc) CLI."
      write_conf "bindcmdaddress ::1"
      write_note ""
      CMDDENY_LOOPBACK_LIST="$CMDDENY_LOOPBACK_LIST ::1"
    fi

  else  # loopback is closed
    echo "...Loopback port is closed for any user to use 'chronyc'."
    # But first, before we block loopback, we need to know if this network block
    # is absolute or is allowing remote-only network access before we use the
    # 'bindcmdaddress'/'cmddeny' directives pair
    if [ "$HAVE_CMD_ACL_NET_REMOTE" = 'y' ]; then
      echo "...BUT remote port is wide open for any user to use 'chronyc'."
      write_note "# Open to any port, minus the loopback subnet"
      # So, its pretty much the ACL_NET_REMOTE minus the ACL_NET_LOOPBACK here
      [ "$HAVE_IPV4" -ge 1 ] && CMDDENY_LOOPBACK_LIST="127.0.0.1"
      [ "$HAVE_IPV6" -ge 1 ] && CMDDENY_LOOPBACK_LIST="$CMDDENY_LOOPBACK_LIST ::1"
      write_conf "bindcmdaddress 0.0.0.0"  # we think this means ANY
      write_note ""
    # shellcheck disable=SC2034
      CMDALLOW_ALL=1
    else
      echo "...also remote port is closed as well.  No network support here."
    # shellcheck disable=SC2034
      CMDDENY_ALL=1
    fi  # HAVE_CMD_ACL_NET_REMOTE
  fi  # HAVE_CMD_ACL_NET_LOOPBACK
fi  # if UNIX-socket/loopback/network
# Done with 'bindcmdaddress'

# Work on 'cmdallow/cmddeny'
# Done with 'cmdallow/cmddeny'

# Adopt a default-deny defensive stance
write_note_cmddeny
write_note "# Adopt a default-deny defensive stance for filtering commands."
write_conf "cmddeny all"

# last line is always empty
write_note ""

echo "Done writing $FILESPEC."

if [ -n "$USER_PRIV_LIST" ]; then
  [ -n "$BUILDROOT" ] && echo ""; echo "You also can execute the following commands:"
  for this_user in $USER_PRIV_LIST; do
    if [ -n "$BUILDROOT" ]; then
      echo "    sudo usermod -a -G $GROUPNAME $this_user"
    else
      $SUDO_BIN usermod -a -G "$GROUPNAME" "$this_user"
    fi
  done
fi

echo ""
echo "Verifying syntax of Chrony config files..."
# Verify the configuration files to be correct, syntax-wise.
$SUDO_BIN "$CHRONYD_BIN" -p -f "${BUILDROOT}${CHROOT_DIR}$FILESPEC" >/dev/null 2>&1
retsts=$?
if [ "$retsts" -ne 0 ]; then
  # do it again but verbosely
  $SUDO_BIN "$CHRONYD_BIN" -p -f "${BUILDROOT}${CHROOT_DIR}$FILESPEC"
  echo "ERROR: $FILESPEC failed syntax check."
  exit 13
fi
echo "${BUILDROOT}${CHROOT_DIR}$FILESPEC passes syntax-check"

if [ "${BUILDROOT:0:1}" == '/' ]; then
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
fi
echo "Done."
exit 0
