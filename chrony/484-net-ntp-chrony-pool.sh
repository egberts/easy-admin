#!/bin/bash
# File: 483-net-ntp-chrony-pool.sh
# Title: NTP Pool settings for Chrony time server
# Description:
#   - Checks for existing /etc/chrony/chrony.conf
#   - Checks for existing 'sourcedir' directive in its config file
#   - Checks for existing directory pointed to by 'sourcedir'
#   - Obtains default IP route
#   - Obtains 'ntpdate'
#   - Check if dhclient daemon exists
#   - Writes a drop-in config file into /etc/chrony/conf.d
#     for declaring NTP pool.
#
#   Does not modify /etc/chrony.conf.
#
# Reads:
#   /etc/chrony.conf
#   /etc/chrony/sources.d/*
# Changes: nothing
# Adds:
#   /etc/chrony/conf.d/ntp_pools.conf
#
# References:
#  CIS Benchmark Debian 10 - 2.2.1.3 - 'server' or 'pool' required
#  #995190 - chrony -p (print config) doesn't show 'sourcedir'
#
# Prerequisites:
#   ntpdate (ntpdate)
#   bind9-dnsutils (dig)
#   iproute2 (ip)
#   iputils-ping (ping)
#   grep (grep)
#   gawk (awk)
#   util-linux (whereis)
#   coreutils (basename, cat, chmod, chown, date, touch)

# shellcheck disable=SC2034
package_tarname="chrony"

BINDROOT=${BINDROOT:-/}
SUDO_BIN=

NTP_POOL_SOURCES_MAX=4  # in case the DNS_based anycast got too big of a pool!
IBURST_MAX_HOPS_CUTOFF=3  # try to stay within local/home LAN
DEFAULT_NTP_SERVER="pool.ntp.org"



######################################
BUILDROOT="/"

ARG1_CHRONY_CONF=${1}

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
  DEFAULT_PREFIX=""  # '/'
  DEFAULT_EXEC_PREFIX="/usr"  # revert  back to default
  DEFAULT_LOCALSTATEDIR=""  # '/'
  EXTENDED_SYSCONFDIR_DIRNAME="chrony"
elif [ "$DISTRO_MANUF" == "Redhat" ]; then
  DEFAULT_PREFIX=""  # '/'
  DEFAULT_EXEC_PREFIX="/usr"  # revert  back to default
  DEFAULT_LOCALSTATEDIR="/var"
  EXTENDED_SYSCONFDIR_DIRNAME="chrony"  # change this often
else
  DEFAULT_PREFIX="/usr"
  DEFAULT_LOCALSTATEDIR="/var"  # or /usr/local/var
  EXTENDED_SYSCONFDIR_DIRNAME="$package_tarname"   # ie., 'bind' vs 'named'
fi
prefix="${prefix:-$DEFAULT_PREFIX}"
sysconfdir="${sysconfdir:-$prefix/etc}"
exec_prefix="${exec_prefix:-${DEFAULT_EXEC_PREFIX:-${prefix}}}"
libdir="${libdir:-$exec_prefix/lib}"
libexecdir=${libexecdir:-$exec_prefix/libexec}
localstatedir="${localstatedir:-"${DEFAULT_LOCALSTATEDIR}"}"
datarootdir=${datarootdir:-$prefix/share}
sharedstatedir=${prefix:-${prefix}/com}
bindir="$exec_prefix/bin"
### runstatedir="$(realpath -m "$localstatedir/run")"
runstatedir="$localstatedir/run"
sbindir="$exec_prefix/sbin"

# bind9 maintainer tweaks
expanded_sysconfdir="${sysconfdir}/${EXTENDED_SYSCONFDIR_DIRNAME}"


# Useful directories that autoconf/configure/autoreconf does not offer.
VARDIR="$prefix/var"
STATEDIR=${STATEDIR:-${VARDIR}/lib/${package_tarname}}
LOG_DIR="$VARDIR/log"  # /var/log

DEFAULT_CHRONY_CONF_FILENAME="chrony.conf"
DEFAULT_CHRONY_DRIFT_FILENAME="chrony.drift"

CHRONY_CONF_DIR="$expanded_sysconfdir"
CHRONY_RUN_DIR="$runstatedir/$package_tarname"  # /run/chrony

CHRONY_LOG_DIR="$LOG_DIR/chrony"  # /var/log/chrony
CHRONY_VAR_LIB_DIR="$VARDIR/lib/$package_tarname"

CHRONY_SOURCESD_DIR="$CHRONY_CONF_DIR/sources.d"
CHRONY_CONFD_DIR="$CHRONY_CONF_DIR/conf.d"  # /etc/chrony/conf.d
CHRONY_KEYS_FILESPEC="$CHRONY_CONF_DIR/chrony.keys"

CHRONY_DRIFT_FILESPEC="$CHRONY_VAR_LIB_DIR/$DEFAULT_CHRONY_DRIFT_FILENAME"

# User supplied chrony.conf variants (offline testing)
if [ -n "$ARG1_CHRONY_CONF" ]; then
  REAL_CONF="$ARG1_CHRONY_CONF"
  CONF_FILENAME="$(basename "$REAL_CONF")"
  CONF_PATHNAME="$(dirname "$REAL_CONF")"
else
  CONF_FILENAME="$DEFAULT_CHRONY_CONF_FILENAME"
  CONF_PATHNAME="$expanded_sysconfdir"
fi
CONF_FILESPEC="$(realpath -m "${BUILDROOT}$CONF_PATHNAME/$CONF_FILENAME")"

# /run/chrony-dhcp/* is populated by /etc/dhcp/dhclient-exit-hooks.d/chrony
# script and executed by 'dhclient' daemon.
DHCP_CHRONY_PATHNAME="$runstatedir/chrony-dhcp/"



if [ ! -e "$CONF_FILESPEC" ]; then
  echo "$CONF_FILESPEC does not exist; aborted."
  exit 9
elif [ ! -f "$CONF_FILESPEC" ]; then
  echo "$CONF_FILESPEC is not a file; aborted."
  exit 10
elif [ ! -r "$CONF_FILESPEC" ]; then
  if [ $UID -ne 0 ]; then
    read -rp "$CONF_FILESPEC is probably read-protected; use SUDO? (N/y): " -eiN
    REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
    if [ "$REPLY" != y ]; then
      echo "Aborted."
      exit 1
    fi
    SUDO_BIN="$(whereis -b sudo | awk '{print $2}')"
  fi
fi

echo "Checking if 'sourcedir' exist in Chrony config file"
# Oh, yeah, we can have multiple 'sourcedir' directives, so use an array
SOURCEDIR_A=("$(grep -e '^[^#]*\s*sourcedir' "$CONF_FILESPEC" | awk '{print $2}')")
if [ -z "${#SOURCEDIR_RESULT[@]}" ]; then
  echo "$FILESPEC is missing 'sourcedir' statement; cannot drop-in config file"
  echo "Aborted."
  exit 9
else
  for this_srcdir in ${SOURCEDIR_A[*]}; do
    if [ ! -d "$this_srcdir" ]; then
      echo "$this_srcdir is not a directory; Aborted."
      exit 10
    fi
  done
fi

# Syntax: create_file FILESPEC [file-permission [owner:group]]
function create_file
{
  $SUDO_BIN touch "$1"
  $SUDO_BIN chmod "$2" "$1"
  $SUDO_BIN chown "$3" "$1"
  $SUDO_BIN cat << CREATE_FILE_EOF | $SUDO_BIN tee "$FILESPEC" >/dev/null
#
# File: $FILENAME
# Path: $FILEPATH
CREATE_FILE_EOF
}

function add_file_headers
{
  cat << CREATE_FILE_EOF | $SUDO_BIN tee -a "$FILESPEC" >/dev/null
# Title: $1
# Creator: $(basename "$0")
# Date: $(date)
# Description:
#
CREATE_FILE_EOF
}

function add_note_pool
{
  if [ -z "$not_a_first_pool" ]; then
    not_a_first_pool=1
  cat << DROPIN_CONF_EOF | $SUDO_BIN tee -a "$FILESPEC" >/dev/null
#
# pool name [option]...
#   The syntax of this directive is similar to that for the server
#   directive, except that it is used to specify a pool of NTP servers
#   rather than a single NTP server. The pool name is expected to
#   resolve to multiple addresses which might change over time.
#
#   This directive can be used multiple times to specify multiple
#   pools.
#
#   All options valid in the server directive can be used in this
#   directive too. There is one option specific to the pool directive:
#
#   maxsources sources
#       This option sets the desired number of sources to be used from
#       the pool. chronyd will repeatedly try to resolve the name until
#       it gets this number of sources responding to requests. The
#       default value is 4 and the maximum value is 16.
#
#   When an NTP source is unreachable, marked as a falseticker, or has
#   a distance larger than the limit set by the maxdistance directive,
#   chronyd will try to replace the source with a newly resolved
#   address of the name.
#
#   An example of the pool directive is
#
#   pool pool.ntp.org iburst maxsources 3
DROPIN_CONF_EOF
  fi
}

function add_note_server
{
  if [ -z "$not_a_first_server" ]; then
    not_a_first_server=1
    cat << DROPIN_CONF_EOF | $SUDO_BIN tee -a "$FILESPEC" >/dev/null
# server hostname [option]...
#   The server directive specifies an NTP server which can be used as a
#   time source. The client-server relationship is strictly
#   hierarchical: a client might synchronise its system time to that of
#   the server, but the server’s system time will never be influenced
#   by that of a client.
#
#   This directive can be used multiple times to specify multiple
#   servers.
#
#   The directive is immediately followed by either the name of the
#   server, or its IP address. It supports the following options:
#
#   minpoll poll
#     This option specifies the minimum interval between requests
#     sent to the server as a power of 2 in seconds. For example,
#     minpoll 5 would mean that the polling interval should not drop
#     below 32 seconds. The default is 6 (64 seconds), the minimum is
#     -6 (1/64th of a second), and the maximum is 24 (6 months). Note
#     that intervals shorter than 6 (64 seconds) should generally not
#     be used with public servers on the Internet, because it might
#     be considered abuse. A sub-second interval will be enabled only
#     when the server is reachable and the round-trip delay is
#     shorter than 10 milliseconds, i.e. the server should be in a
#     local network.
#
#   maxpoll poll
#     This option specifies the maximum interval between requests
#     sent to the server as a power of 2 in seconds. For example,
#     maxpoll 9 indicates that the polling interval should stay at or
#     below 9 (512 seconds). The default is 10 (1024 seconds), the
#     minimum is -6 (1/64th of a second), and the maximum is 24 (6
#     months).
#
#   iburst
#     With this option, chronyd will start with a burst of 4-8
#     requests in order to make the first update of the clock sooner.
#     It will also repeat the burst every time the source is switched
#     from the offline state to online with the online command in
#     chronyc.
#
#   burst
#     With this option, chronyd will send a burst of up to 4 requests
#     when it cannot get a good measurement from the server. The
#     number of requests in the burst is limited by the current
#     polling interval to keep the average interval at or above the
#     minimum interval, i.e. the current interval needs to be at
#     least two times longer than the minimum interval in order to
#     allow a burst with two requests.
#
#   key ID
#     The NTP protocol supports a message authentication code (MAC)
#     to prevent computers having their system time upset by rogue
#     packets being sent to them. The MAC is generated as a function
#     of a key specified in the key file, which is specified by the
#     keyfile directive.
#
#     The key option specifies which key (with an ID in the range 1
#     through 2^32-1) should chronyd use to authenticate requests
#     sent to the server and verify its responses. The server must
#     have the same key for this number configured, otherwise no
#     relationship between the computers will be possible.
#
#     If the server is running ntpd and the output size of the hash
#     function used by the key is longer than 160 bits (e.g. SHA256),
#     the version option needs to be set to 4 for compatibility.
#
#   nts
#     This option enables authentication using the Network Time
#     Security (NTS) mechanism. Unlike with the key option, the
#     server and client do not need to share a key in a key file. NTS
#     has a Key Establishment (NTS-KE) protocol using the Transport
#     Layer Security (TLS) protocol to get the keys and cookies
#     required by NTS for authentication of NTP packets.
#
#   maxdelay delay
#     chronyd uses the network round-trip delay to the server to
#     determine how accurate a particular measurement is likely to
#     be. Long round-trip delays indicate that the request, or the
#     response, or both were delayed. If only one of the messages was
#     delayed the measurement error is likely to be substantial.
#
#     For small variations in the round-trip delay, chronyd uses a
#     weighting scheme when processing the measurements. However,
#     beyond a certain level of delay the measurements are likely to
#     be so corrupted as to be useless. (This is particularly so on
#     dial-up or other slow links, where a long delay probably
#     indicates a highly asymmetric delay caused by the response
#     waiting behind a lot of packets related to a download of some
#     sort).
#
#     If the user knows that round trip delays above a certain level
#     should cause the measurement to be ignored, this level can be
#     defined with the maxdelay option. For example, maxdelay 0.3
#     would indicate that measurements with a round-trip delay of 0.3
#     seconds or more should be ignored. The default value is 3
#     seconds and the maximum value is 1000 seconds.
#
#   maxdelayratio ratio
#     This option is similar to the maxdelay option above. chronyd
#     keeps a record of the minimum round-trip delay amongst the
#     previous measurements that it has buffered. If a measurement
#     has a round trip delay that is greater than the maxdelayratio
#     times the minimum delay, it will be rejected.
#
#   maxdelaydevratio ratio
#     If a measurement has a ratio of the increase in the round-trip
#     delay from the minimum delay amongst the previous measurements
#     to the standard deviation of the previous measurements that is
#     greater than the specified ratio, it will be rejected. The
#     default is 10.0.
#
#   mindelay delay
#     This option specifies a fixed minimum round-trip delay to be
#     used instead of the minimum amongst the previous measurements.
#     This can be useful in networks with static configuration to
#     improve the stability of corrections for asymmetric jitter,
#     weighting of the measurements, and the maxdelayratio and
#     maxdelaydevratio tests. The value should be set accurately in
#     order to have a positive effect on the synchronisation.
#
#   asymmetry ratio
#     This option specifies the asymmetry of the network jitter on
#     the path to the source, which is used to correct the measured
#     offset according to the delay. The asymmetry can be between
#     -0.5 and +0.5. A negative value means the delay of packets sent
#     to the source is more variable than the delay of packets sent
#     from the source back. By default, chronyd estimates the
#     asymmetry automatically.
#
#   offset offset
#     This option specifies a correction (in seconds) which will be
#     applied to offsets measured with this source. It’s particularly
#     useful to compensate for a known asymmetry in network delay or
#     timestamping errors. For example, if packets sent to the source
#     were on average delayed by 100 microseconds more than packets
#     sent from the source back, the correction would be -0.00005
#     (-50 microseconds). The default is 0.0.
#
#   minsamples samples
#     Set the minimum number of samples kept for this source. This
#     overrides the minsamples directive.
#
#   maxsamples samples
#     Set the maximum number of samples kept for this source. This
#     overrides the maxsamples directive.
#
#   filter samples
#     This option enables a median filter to reduce noise in NTP
#     measurements. The filter will reduce the specified number of
#     samples to a single sample. It is intended to be used with very
#     short polling intervals in local networks where it is
#     acceptable to generate a lot of NTP traffic.
#
#   offline
#     If the server will not be reachable when chronyd is started,
#     the offline option can be specified. chronyd will not try to
#     poll the server until it is enabled to do so (by using the
#     online command in chronyc).
#
#   auto_offline
#     With this option, the server will be assumed to have gone
#     offline when sending a request fails, e.g. due to a missing
#     route to the network. This option avoids the need to run the
#     offline command from chronyc when disconnecting the network
#     link. (It will still be necessary to use the online command
#     when the link has been established, to enable measurements to
#     start.)
#
#   prefer
#     Prefer this source over sources without the prefer option.
#
#   noselect
#     Never select this source. This is particularly useful for
#     monitoring.
#
#   trust
#     Assume time from this source is always true. It can be rejected
#     as a falseticker in the source selection only if another source
#     with this option does not agree with it.
#
#   require
#     Require that at least one of the sources specified with this
#     option is selectable (i.e. recently reachable and not a
#     falseticker) before updating the clock. Together with the trust
#     option this might be useful to allow a trusted authenticated
#     source to be safely combined with unauthenticated sources in
#     order to improve the accuracy of the clock. They can be
#     selected and used for synchronisation only if they agree with
#     the trusted and required source.
#
#   xleave
#     This option enables the interleaved mode of NTP. It enables the
#     server to respond with more accurate transmit timestamps (e.g.
#     kernel or hardware timestamps), which cannot be contained in
#     the transmitted packet itself and need to refer to a previous
#     packet instead. This can significantly improve the accuracy and
#     stability of the measurements.
#
#     The interleaved mode is compatible with servers that support
#     only the basic mode. Note that even servers that support the
#     interleaved mode might respond in the basic mode as the
#     interleaved mode requires the servers to keep some state for
#     each client and the state might be dropped when there are too
#     many clients (e.g. clientloglimit is too small), or it might be
#     overwritten by other clients that have the same IP address
#     (e.g. computers behind NAT or someone sending requests with a
#     spoofed source address).
#
#     The xleave option can be combined with the presend option in
#     order to shorten the interval in which the server has to keep
#     the state to be able to respond in the interleaved mode.
#
#   polltarget target
#     Target number of measurements to use for the regression
#     algorithm which chronyd will try to maintain by adjusting the
#     polling interval between minpoll and maxpoll. A higher target
#     makes chronyd prefer shorter polling intervals. The default is
#     8 and a useful range is from 6 to 60.
#
#   port port
#     This option allows the UDP port on which the server understands
#     NTP requests to be specified. For normal servers this option
#     should not be required (the default is 123, the standard NTP
#     port).
#
#   ntsport port
#     This option specifies the TCP port on which the server is
#     listening for NTS-KE connections when the nts option is
#     enabled. The default is 4460.
#
#   presend poll
#     If the timing measurements being made by chronyd are the only
#     network data passing between two computers, you might find that
#     some measurements are badly skewed due to either the client or
#     the server having to do an ARP lookup on the other party prior
#     to transmitting a packet. This is more of a problem with long
#     sampling intervals, which might be similar in duration to the
#     lifetime of entries in the ARP caches of the machines.
#
#     In order to avoid this problem, the presend option can be used.
#     It takes a single integer argument, which is the smallest
#     polling interval for which an extra pair of NTP packets will be
#     exchanged between the client and the server prior to the actual
#     measurement. For example, with the following option included in
#     a server directive:
#
#         presend 9
#
#     when the polling interval is 512 seconds or more, an extra NTP
#     client packet will be sent to the server a short time (2
#     seconds) before making the actual measurement.
#
#     If the presend option is used together with the xleave option,
#     chronyd will send two extra packets instead of one.
#
#   minstratum stratum
#     When the synchronisation source is selected from available
#     sources, sources with lower stratum are normally slightly
#     preferred. This option can be used to increase stratum of the
#     source to the specified minimum, so chronyd will avoid
#     selecting that source. This is useful with low stratum sources
#     that are known to be unreliable or inaccurate and which should
#     be used only when other sources are unreachable.
#
#   version version
#     This option sets the NTP version of packets sent to the server.
#     This can be useful when the server runs an old NTP
#     implementation that does not respond to requests using a newer
#     version. The default version depends on whether a key is
#     specified by the key option and which authentication hash
#     function the key is using. If the output size of the hash
#     function is longer than 160 bits, the default version is 3 for
#     compatibility with older chronyd servers. Otherwise, the
#     default version is 4.

DROPIN_CONF_EOF
  fi
}


function write_conf
{
  cat << WRITE_CONF_EOF | $SUDO_BIN tee -a "$FILESPEC" >/dev/null
$1
WRITE_CONF_EOF
}

function write_note
{
  cat << WRITE_NOTE_EOF | $SUDO_BIN tee -a "$FILESPEC" >/dev/null
$1
WRITE_NOTE_EOF
}

function annotate
{
  if [ "$ANNOTATION" -ne 0 ]; then
    CHRONY_CONF_A+=("")
    CHRONY_CONF_A+=("# $1")
  fi
}

# What do I have here?

DEFAULT_ROUTE="$(ip -o route list scope global | awk '{print $3}')"
echo ""
# See if our local router is also offering time serving.
if [ -z "$DEFAULT_ROUTE" ]; then
  echo "...no default IP route found"
  echo "...this machine has no Internet access (but maybe locally).  Aborted."
  exit 1
else
  echo "Default route is '$DEFAULT_ROUTE'; something to try for an NTP server..."
fi

# Go straight to the meat: Check our global NTP server pool for accessibility
# Get 'ntpdate', a great non-root NTP protocol tester

echo "Searching for 'ntpdate' utility..."
NTPDATE="$(whereis -b ntpdate | awk '{print $2}')"
echo "...Found: $NTPDATE"
if [ ! -e "$NTPDATE" ]; then
  echo "Running 'apt install ntpdate'..."
  $SUDO_BIN apt install ntpdate
  RETSTS=$?
  if [ $RETSTS -ne 0 ]; then
    echo "Error running 'apt install ntpdate': Error $RETSTS"
    exit $RETSTS
  fi
fi

# See if local ISC DHCP client has gathered any NTP servers
# /run/ntp.conf.dhcp or /run/chrony-dhcp/* has any entries
# Steal NTPD's old capturing of new_ntp_servers, if any.

CHRONY_DHCP_NTP_LIST=
CHRONY_DHCP_NTP_LIST_COUNT=0
# Obtain Chrony's copy of DHCP-info containing NTP server(s), if any
echo ""
echo "Checking if Chrony already got the NTP servers given out by a DHCP server"
FILENAME="*.sources"
FILEPATH="$localstatedir/run/chrony-dhcp"
FILESPEC="$FILEPATH/$FILENAME"
# Wildcard subdirectory
# shellcheck disable=SC2086 disable=SC2012
FILE_CNT="$(ls -1 $FILESPEC 2>/dev/null | wc -l)"
if [ "$FILE_CNT" -ge 1 ]; then
  echo "Checking '$FILESPEC' subdirectory for any files..."
  # shellcheck disable=SC2086 disable=SC2012
  NTP_LIST=$(grep -E '^(\s*(~#)*\s*server\s+)' $FILESPEC| awk '{print $2}' | sort -u | xargs)
  CHRONY_DHCP_NTP_LIST="$NTP_LIST"
  CHRONY_DHCP_NTP_LIST_COUNT="$(echo "$NTP_LIST" | wc -w)"
  if [ "$CHRONY_DHCP_NTP_LIST_COUNT" -ge 1 ]; then
    echo "...We found $CHRONY_DHCP_NTP_LIST_COUNT NTP servers."
    echo "...They are: $CHRONY_DHCP_NTP_LIST."
    HAVE_NTP_DHCP=1
  else
    echo "...Nope.  NTPD has an empty NTP list in '$FILESPEC'."
  fi
else
  echo "...Nope; File $FILESPEC is missing."
  echo "...ISC dhclient is not maintaining a NTP list in '$FILESPEC'."
fi

NTPD_DHCP_NTP_LIST_COUNT=0
NTPD_DHCP_NTP_LIST=
# Obtain NTPD's copy of DHCP-info containing NTP server(s), if any
echo ""
echo "Checking if NTPD already got the NTP servers given out by a DHCP server"
FILENAME="ntp.conf.dhcp"
FILEPATH="$localstatedir/run"
FILESPEC="$FILEPATH/$FILENAME"
if [ -e "$FILESPEC" ]; then
  NTP_LIST=$(grep -E '^(\s*(~#)*\s*server\s+)' "$FILESPEC"| awk '{print $2}' | sort -u | xargs)
  NTPD_DHCP_NTP_LIST="$NTP_LIST"
  NTPD_DHCP_NTP_LIST_COUNT="$(echo "$NTP_LIST" | wc -w)"
  if [ "$NTPD_DHCP_NTP_LIST_COUNT" -ge 1 ]; then
    echo "...We found $NTPD_DHCP_NTP_LIST_COUNT NTP servers."
    echo "...They are: $NTPD_DHCP_NTP_LIST."
    HAVE_NTP_DHCP=1
  else
    echo "...Nope.  NTPD has an empty NTP list in '$FILESPEC'."
  fi
else
  echo "...Nope; File '$FILESPEC' is missing."
  echo "...ISC dhclient is not maintaining a NTP list in '$FILESPEC'."
fi
((DHCP_NTP_LIST_COUNT=NTPD_DHCP_NTP_LIST_COUNT+CHRONY_DHCP_NTP_LIST_COUNT))
NTP_LIST="$CHRONY_DHCP_NTP_LIST $NTPD_DHCP_NTP_LIST"
DHCP_NTP_LIST="$(echo "$NTP_LIST"|xargs -n1|sort -u|xargs)"

# Check our global NTP server pool for accessibility
echo ""
echo "Test for global '$DEFAULT_NTP_SERVER' NTP time serving capability..."
$NTPDATE -q $DEFAULT_NTP_SERVER
RETSTS=$?
HAVE_NTP_WORLD=0
if [ "$RETSTS" -eq 0 ]; then
  echo "...Got a response from '$DEFAULT_NTP_SERVER'..."
  HAVE_NTP_WORLD=1
  NTP_SERVERS_LIST_EXTERNAL="$DEFAULT_NTP_SERVER"
else
  echo "...WARNING: No response from '$DEFAULT_NTP_SERVER'; firewalled?"
  NTP_SERVERS_LIST_EXTERNAL=""
fi

HAVE_NTP_LOCAL=0
NTP_SERVERS_LIST_INTERNAL=
if [ "$CHRONY_DHCP_NTP_LIST_COUNT" -eq 0 ]; then
  # Got a working default router, check for NTP server port
  echo "Trying router '$DEFAULT_ROUTE' for any NTP server port..."
  "$NTPDATE" -q "$DEFAULT_ROUTE"
  RETSTS=$?
  if [ "$RETSTS" -eq 0 ]; then
    echo "...SUCCESS! Router '$DEFAULT_ROUTE' has an NTP server."
    HAVE_NTP_LOCAL=1
    NTP_SERVERS_LIST_INTERNAL="$DEFAULT_ROUTE"
  fi
fi

NEED_NTP_SERVER=0
# Neither Internet nor our local router has an accessible NTP server
if [ "$HAVE_NTP_WORLD" -eq 0 ] && \
   [ "$HAVE_NTP_DHCP" -eq 0 ] && \
   [ "$HAVE_NTP_LOCAL" -eq 0 ]; then
  # Don't worry, we will network-test verify all new NTP server entries.
  NEED_NTP_SERVER=1

  # Does your firewall block NTP packets yet provides NTP
  # time servers?
  read -rp "Does the firewall on this machine blocks any NTP packets? (N/y): "
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ "$REPLY" = 'y' ]; then
    echo "You will not be needing an accurate time keeper, that is"
    echo " until this firewall is fixed.  Aborted."
    exit 1
  fi

  echo ""
  echo "Gateway routers may block NTP protocol yet serve as your bastion host"
  echo "that insulate NTP protocols from the outside by being their"
  echo "own NTP time server as well."
  echo "You may know this by not getting any NTP packets on your machine"
  echo "from the outside your gateway router."
  read -rp "Is the firewall at your gateway router blocking any NTP packets? (N/y): "
  REPLY="$(echo "${REPLY:0:1}" | awk '{print tolower($1)}')"
  if [ "$REPLY" = 'y' ]; then
    # Query the router for NTP port 123
    echo "You will not be needing an accurate time keeper, that is"
    echo " until this firewall is fixed).  Aborted."
    exit 1
  fi
fi
echo ""

NTP_SERVERS_LIST_COUNT=0
NTP_SERVERS_LIST="$NTP_SERVERS_LIST $NTP_SERVERS_LIST_EXTERNAL"
NTP_SERVERS_LIST="$NTP_SERVERS_LIST $NTP_SERVERS_LIST_INTERNAL"
NTP_SERVERS_LIST="$NTP_SERVERS_LIST $DHCP_NTP_LIST"
NTP_SERVERS_LIST="$(echo "$NTP_SERVERS_LIST" | xargs -n1 | sort -u | xargs)"
NTP_SERVERS_LIST_COUNT="$(echo "$NTP_SERVERS_LIST" | wc -w)"


# If DNS name has the word 'pool', odds are we got excellent # of peers
echo "$NTP_SERVERS_LIST" | grep -E 'pool' >/dev/null 2>&1
RETSTS=$?
if [ "$RETSTS" -eq 0 ]; then
  echo "Found the word 'pool' in this server list."
  echo "Counting how many are actually in that pool..."
  DIG_BIN="$(whereis -b dig|awk '{print $2}')"
  if [ -e "$DIG_BIN" ]; then
    POOL_COUNT=0
    for this_ntp in $NTP_SERVERS_LIST; do
      count="$("$DIG_BIN" +short "$this_ntp" 2>/dev/null | wc -l)"
      ((POOL_COUNT+=count))
    done
    RETSTS=0
    if [ "$RETSTS" -ne 0 ]; then
      # We cannot know how many are behind DNS anycast of 'pool.ntp.org'
      # But we only need 3 servers in which to sync with, plus
      # whatever NTP time server we find on our local gateway router
      (( NTP_SERVERS_LIST_COUNT=NTP_SERVERS_LIST_COUNT+((NTP_POOL_SOURCES_MAX-1)) ))
      echo "Adjust total NTP server count to $NTP_SERVERS_LIST_COUNT"
    else
      # got precise number of entrants in this NTP pool
      (( NTP_SERVERS_LIST_COUNT=NTP_SERVERS_LIST_COUNT+POOL_COUNT-1 ))
    fi
  fi
fi

# Now autodiscovery is done, let us prompt for any user-defined NTP servers

if [ "$NTP_SERVERS_LIST_COUNT" -lt "$NTP_POOL_SOURCES_MAX" ]; then
  echo ""
  echo "We only auto-discovered $NTP_SERVERS_LIST_COUNT; we need more."
  read -rp "Do you know the FQDN or IP address(es) to any others? (N/y): "
  REPLY="echo ${REPLY:0:1} | awk {'print tolower($1)'}"
  if [ "$REPLY" = 'y' ]; then
    echo "TBD:"
  fi
else
  echo "No need to ask you for more NTP servers."
fi
# echo "NTP_SERVERS_LIST_EXTERNAL: $NTP_SERVERS_LIST_EXTERNAL"
# echo "NTP_SERVERS_LIST_INTERNAL: $NTP_SERVERS_LIST_INTERNAL"
# echo "DHCP_NTP_LIST: $DHCP_NTP_LIST"

echo "NTP server(s): $NTP_SERVERS_LIST"
echo "NTP server count: $NTP_SERVERS_LIST_COUNT"


# Do you know what kind of NTP server they are using?  x
#   if chronyd, then use 'xleave', 'smoothtime', 'leapsecmode' option
#   if Windows, then insert 'maxdistance 16.0'
#   if ntp, no change
# Ask for ISO Country code for pool settings?  i.e., US.pool.ntp.org

FILENAME="ntp_pools.sources"
FILEPATH="$CHRONY_SOURCESD_DIR"
FILESPEC="$(realpath "$BINDROOT$FILEPATH/$FILENAME")"

create_file "$FILESPEC" 0640 _chrony:_chrony
add_file_headers "NTP Pools for Chrony NTP daemon"
echo "Creating Chrony $FILESPEC drop-in configuration file..."


# for 'maxsources' on 'pool' keyword, use this command:
#     count="$("$DIG_BIN" +short "$this_ntp" 2>/dev/null | wc -l)"

# Now we gotta figure out this 'iburst'/'burst' thingie.
# and 'maxsources' in case this is a pool.
#
# A good rule is to use iburst for hops less than 2
# Hop-wise, we could use ping for their robust shell error code reporting
for this_ntp in $NTP_SERVERS_LIST; do

  write_note ""
  # We do pool-size count firstly to decide on the 'server'/'pool' directive
  # this time, ignore the 'pool' in the hostname, we're proving this
  pool_count="$("$DIG_BIN" +short "$this_ntp" 2>/dev/null | wc -l)"
  if [ "$pool_count" -ge "$NTP_POOL_SOURCES_MAX" ]; then
    # Set up the configuration line for this NTP server item
    WRITECONF="pool $this_ntp"
    add_note_pool

    # Then there is no reason for a burst/iburst in a big pool
    # Compute max_sources, cap it at 4. TODO: Prompt for this?
    write_note ""
    write_note "# Last 'dig +short $this_ntp' revealed $pool_count NTP servers"
    if [ "$pool_count" -gt "$NTP_POOL_SOURCES_MAX" ]; then
      max_sources="$NTP_POOL_SOURCES_MAX"
      write_note "# Exceeded our NTP_POOL_SOURCES_MAX=$NTP_POOL_SOURCES_MAX so we capped that."
    else
      max_sources=$pool_count
    fi
    # Go ahead and add the 'maxsources' attribute
    WRITECONF="$WRITECONF maxsources $max_sources"
  else
    # Set up the configuration line for this NTP server item
    WRITECONF="server $this_ntp"
    add_note_server
  fi

  # count how many hops away
  # Ummm, might be a new replacement NTP via DNS-based anycast,
  # not necessarily a pool-quality NTP servers by hostname.
  # Now, is that NTP server too many hops away to use this 'iburst'/'burst'?
  hops_away=1  # start at hop #1
  while [ "$hops_away" -lt 8 ]; do
    /bin/ping -W3 -c1 -t $hops_away "$this_ntp"
    retsts=$?
    if [ $retsts -eq 0 ]; then
      break
    fi
    ((hops_away+=1))
  done

  if [ "$hops_away" -lt "$IBURST_MAX_HOPS_CUTOFF" ]; then
    echo "NTP '$this_ntp' server is only $hops_away hops away; "
    echo "   let us use 'iburst' attribute"
    write_note "# Last 'ping -c1 -W3 -t $this_ntp' revealed $hops_away hops away"
    WRITECONF="$WRITECONF iburst"
  else
    echo "NTP '$this_ntp' server is $hops_away hops far away:"
    echo "   Probably should not use 'iburst' attribute"
    write_note "# NTP '$this_ntp' is $hops_away hops away & too far away for iburst"
    write_note "# \$IBURST_MAX_HOPS_CUTOFF=$IBURST_MAX_HOPS_CUTOFF "
  fi

  write_conf "$WRITECONF"
done

echo ""
echo "Look at your new configuration file at $FILESPEC:"
cat "$FILESPEC"
echo ""


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


# Verify the configuration files to be correct, syntax-wise.
chronyd -p -f "$FILESPEC" >/dev/null 2>&1
retsts=$?
if [ "$retsts" -ne 0 ]; then
  # rerun it but with verbosity
  chronyd -p -f "$FILESPEC"
  echo "ERROR: $FILESPEC failed syntax check."
  exit 13
fi
echo "$FILESPEC passes syntax-check"

# Objective is to 'enable' chrony service
# and only restart or try-restart the service
# It is not intended to start anything
# Just reload any active Chrony daemon
# That's the operator's job.
#
# If it was stopped, it stays stopped
# If it was started, it gets restarted/reloaded
systemctl --quiet is-enabled chrony.service
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "Enabling Chrony service..."
  systemctl enable chrony.service
fi

echo ""
systemctl --quiet is-active chrony.service
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "Trying to reload or restart Chrony service..."
  systemctl try-reload-or-restart chrony.service
  echo "WARNING: You may have to start it yourself."
  echo "Chrony daemon status: $(systemctl is-active chrony.service)"
  exit $?  # pass-along 'is-active' errcode
else
  echo "Restarting Chrony service..."
  systemctl restart chrony.service
fi
echo "Chrony daemon status: $(systemctl is-active chrony.service): Done."
exit $?  # pass-along 'is-active' errcode


