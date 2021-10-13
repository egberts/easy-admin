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
BUILDROOT=${1:-/}  # Pass BUILDROOT=/tmp for pseudo-dry-runs

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

# shellcheck disable=SC2034
package_tarname="chrony"

# configure/autogen/autoreconf -------------------------------------
# most configurable variables used here are found in
# configure/autogen/autoconf but are capitalized for readablity here
#
# maintainer default (Chrony)
#   prefix=/usr/local
#   libexecdir=$prefix/libexec
#   datarootdir=$prefix/share
#   sysconfdir=$prefix/etc
#   localstatedir=$prefix/var
#   libdir=$exec_prefix/lib
#   bindir=$exec_prefix/bin
#   sbindir=$exec_prefix/sbin
#   datadir=$datarootdir

# Debian maintainer however applies this:
#   libdir=/usr/lib
#   SYSROOT=/
#   libexecdir=/usr/lib

# All we are really concern about are:
#   prefix/prefix
#   sysconfdir/sysconfdir
#   localstatedir/localstatedir

DISTRO_MANUF="$(lsb_release -i|awk -F: '{print $2}'|xargs)"
if [ "$DISTRO_MANUF" == "Debian" ]; then
  DEFAULT_prefix=""  # '/'
  DEFAULT_exec_prefix="/usr"  # revert  back to default
  DEFAULT_LOCALSTATEDIR=""  # '/'
  EXTENDED_sysconfdir_DIRNAME="chrony"
elif [ "$DISTRO_MANUF" == "Redhat" ]; then
  DEFAULT_prefix=""  # '/'
  DEFAULT_exec_prefix="/usr"  # revert  back to default
  DEFAULT_LOCALSTATEDIR="/var"
  EXTENDED_sysconfdir_DIRNAME="chrony"  # change this often
else
  DEFAULT_prefix="/usr"
  DEFAULT_LOCALSTATEDIR="/var"  # or /usr/local/var
  EXTENDED_sysconfdir_DIRNAME="$package_tarname"   # ie., 'bind' vs 'named'
fi
prefix="${prefix:-$DEFAULT_prefix}"
sysconfdir="${sysconfdir:-$prefix/etc}"
exec_prefix="${exec_prefix:-${DEFAULT_exec_prefix:-${prefix}}}"
libdir="${libdir:-$exec_prefix/lib}"
libexecdir=${libexecdir:-$exec_prefix/libexec}
localstatedir="${localstatedir:-"${DEFAULT_LOCALSTATEDIR}"}"
# datarootdir=${datarootdir:-$prefix/share}
# sharedstatedir=${prefix:-${prefix}/com}
# bindir="$exec_prefix/bin"
### runstatedir="$(realpath -m "$localstatedir/run")"
runstatedir="$localstatedir/run"
# sbindir="$exec_prefix/sbin"

# bind9 maintainer tweaks
expanded_sysconfdir="${sysconfdir}/${EXTENDED_sysconfdir_DIRNAME}"

# Useful directories that autoconf/configure/autoreconf does not offer.
VARDIR="$prefix/var"
STATEDIR=${STATEDIR:-${VARDIR}/lib/${package_tarname}}
# LOG_DIR="$VARDIR/log"  # /var/log

# DEFAULT_CHRONY_CONF_FILENAME="chrony.conf"
# DEFAULT_CHRONY_DRIFT_FILENAME="chrony.drift"
DEFAULT_CHRONY_SOCK_FILENAME="chrony.sock"

CHRONY_RUN_DIR="$runstatedir/$package_tarname"  # /run/chrony
# CHRONY_VAR_LIB_DIR="$VARDIR/lib/$package_tarname"

CHRONY_CONFD_DIR="$expanded_sysconfdir/conf.d"  # /etc/chrony/conf.d
# CHRONY_SOURCESD_DIR="$expanded_sysconfdir/sources.d"  # /etc/chrony/sources.d
# CHRONY_LOG_DIR="$LOG_DIR/chrony"  # /var/log/chrony
# CHRONY_DRIFT_FILESPEC="$CHRONY_VAR_LIB_DIR/$DEFAULT_CHRONY_DRIFT_FILENAME"
# CHRONY_KEYS_FILESPEC="$expanded_sysconfdir/chrony.keys"
CHRONY_SOCK_FILESPEC="$CHRONY_RUN_DIR/$DEFAULT_CHRONY_SOCK_FILENAME"

echo "final configure/autogen/autoreconf settings:"
echo "  prefix:        $prefix"
echo "  sysconfdir:    $sysconfdir"
echo "  LOCALSTATEDIR: $localstatedir"
echo "  RUNDIR: $RUNDIR or $runstatedir"
#
ANNOTATE=${ANNOTATE:-y}

if [[ -z "$BUILDROOT" ]] || [[ "$BUILDROOT" = '/' ]]; then
  SUDO_BIN=sudo
  echo "Writing ALL files as 'root'..."
else
  echo "Writing ALL files into $BUILDROOT as user '$USER')..."
fi

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
  [[ -n "$SUDO_BIN" ]] && $SUDO_BIN touch "$FILESPEC"
  [[ -n "$SUDO_BIN" ]] && $SUDO_BIN chmod "$1" "$FILESPEC"
  [[ -n "$SUDO_BIN" ]] && $SUDO_BIN chown "$2" "$FILESPEC"
  cat << CREATE_FILE_EOF | $SUDO_BIN tee "$FILESPEC" >/dev/null
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
  cat << WRITE_CONF_EOF | $SUDO_BIN tee -a "$FILESPEC" >/dev/null
$1
WRITE_CONF_EOF
}

function write_note
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << WRITE_NOTE_EOF | $SUDO_BIN tee -a "$FILESPEC" >/dev/null
$1
WRITE_NOTE_EOF
  fi
}

function write_note_bindcmdaddress
{
  if [ "$ANNOTATE" = "y" ]; then
    cat << CHRONY_DROPIN_CONF_EOF | $SUDO_BIN tee -a "$FILESPEC" >/dev/null
CHRONY_DROPIN_CONF_EOF
  fi
}

function write_note_cmdallow
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << CHRONY_DROPIN_CONF_EOF | $SUDO_BIN tee -a "$FILESPEC" >/dev/null
CHRONY_DROPIN_CONF_EOF
  fi
}

function write_note_cmddeny
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << CHRONY_DROPIN_CONF_EOF | $SUDO_BIN tee -a "$FILESPEC" >/dev/null
CHRONY_DROPIN_CONF_EOF
  fi
}

function write_note_cmdport
{
  if [ "$ANNOTATE" = 'y' ]; then
    cat << CHRONY_DROPIN_CONF_EOF | $SUDO_BIN tee -a "$FILESPEC" >/dev/null
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
    write_conf "bindcmdaddress $CHRONY_SOCK_FILESPEC"
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


echo ""
echo "Verifying syntax of Chrony config files..."
# Verify the configuration files to be correct, syntax-wise.
$CHRONYD_BIN -p -f "$FILESPEC" >/dev/null 2>&1
retsts=$?
if [ "$retsts" -ne 0 ]; then
  # do it again but verbosely
  $CHRONYD_BIN -p -f "$FILESPEC"
  echo "ERROR: $FILESPEC failed syntax check."
  exit 13
fi
echo "$FILESPEC passes syntax-check"

echo "Reloading config file in chronyd daemon..."
chronyc reload sources >/dev/null 2>&1
retsts=$?
if [ "$retsts" -ne 0 ]; then
  systemctl --quiet is-enabled chrony.service
  retsts=$?
  if [ "$retsts" -ne 0 ]; then
    systemctl enable chrony.service
  fi
  systemctl --quiet is-active chrony.service
  retsts=$?
  if [ "$retsts" -ne 0 ]; then
    systemctl try-reload-or-restart chrony.service
  else
    systemctl start chrony.service
  fi
fi
echo "Done."
exit 0
