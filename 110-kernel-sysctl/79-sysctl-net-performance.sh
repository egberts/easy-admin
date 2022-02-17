#!/bin/bash
# File: 439-net-sysctl-performance.sh
# Title:  Set kernel to high-performance via sysctl
# Description:
#

DATE="$(date)"
CREATOR="$(basename "$0")"


sysconfdir="${sysconfdir:-/etc}"

SYSCTL_FILENAME="sysctl.conf"
SYSCTL_FILESPEC="$sysconfdir/$SYSCTL_FILENAME"

SYSCTLD_DIRNAME="sysctl.d"
SYSCTLD_DIRPATH="$sysconfdir/$SYSCTLD_DIRNAME"

echo "Default settings for $SYSCTLD_DIRPATH."

if [ -f "$SYSCTL_FILESPEC" ]; then
  echo "WARNING: /etc/sysctl.conf exists; delete, disable or rename it away"
fi

DISTRO_DEFAULT_SYSCTL_FILESPEC="$SYSCTLD_DIRPATH/99-sysctl.conf"
if [ -f "$DISTRO_DEFAULT_SYSCTL_FILESPEC" ]; then
  echo "File $DISTRO_DEFAULT_SYSCTL_FILESPEC exists."
  echo "It starts with 99, so any of our earlier settings would be "
  echo "overridden by this distro default sysctl setting.  Remove it."
  echo "ERROR: /etc/sysctl.d/99-sysctl.conf exists; delete or rename it away"
  exit 9
fi

echo ""
echo "Populating /etc/sysctl.d with sysctl settings..."
FILENAME=13-randomize_va_space.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title: Randomize kernel virtual address at each executable load
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:
#
# When setting the value to 0, no address space are randomized.
#
# When setting the value to 1, address space is randomized.
# This includes the positions of the stack itself, virtual
# dynamic shared object (VDSO) page, and shared memory regions.
#
# Setting the option to value 2 will be similar to 1, and
# adds data segments as well.
#
# For most systems, this setting is the default and the
# most secure setting.
kernel.randomize_va_space = 2

EOF

FILENAME=06-net_core_netdev_max_backlog.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title:  Maximum size of interface's receive queue
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:
#   This parameter sets the maximum size of the network
#   interface's receive queue.  The queue is used to store
#   received frames after removing them from the network
#   adapter's ring buffer. High speed adapters should use
#   a high value to prevent the queue from becoming full
#   and dropping packets causing retransmits.  The
#   default value of netdev_max_backlog is typically
#   1000 frames.
#
#   Maximum backlog number of unprocessed packets before kernel drops
#
# Reference:
#  - KVM Network Performance - Best Practices and Tuning Recommendations
#      https://www.ibm.com/downloads/cas/ZVJGQX8E
#
net.core.netdev_max_backlog = 25000
EOF

FILENAME=05-memory_usage_network_stack.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title: Memory usage by network stack in the operating system
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:
# Reference:
#  - KVM Network Performance - Best Practices and Tuning Recommendations
#      https://www.ibm.com/downloads/cas/ZVJGQX8E
#
net.core.wmem_max = 12582912
net.core.rmem_max = 12582912

# Setting maximum option memory (TBR)
net.core.optmem_max = 524287

# Increase TCP read/write buffers toenable scaling to a
# larger window size.  Larger window's increase the
# amount of data to be transferred before an
# acknowledgement (ACK) is required.  This reduces
# overall latencies and results in increased throughput.
#
# This setting is typically set to a very conservative
# value of 262,144 bytes.  It is recommended this
# value be set a slarge as the kernel allows.  The
# value used in here was 4,136,960 bytes.  However,
# 4.x+ kernels accept values over 16MB.
net.ipv4.tcp_wmem = 10240 87380 12582912

#  TCP window size for single connections:
#
#   The receive buffer (RX_WINDOW) size must be at least as large as the
#   Bandwidth-Delay Product of the communication link between the sender and
#   receiver. Due to the variations of RTT, you may want to increase the buffer
#   size up to 2 times the Bandwidth-Delay Product. Reference page 289 of
#   "TCP/IP Illustrated, Volume 1, The Protocols" by W. Richard Stevens.
#
#   At 10Gb speeds, use the following formula::
#
#       RX_WINDOW >= 1.25MBytes * RTT(in milliseconds)
#       Example for RTT with 100us: RX_WINDOW = (1,250,000 * 0.1) = 125,000
#
#   RX_WINDOW sizes of 256KB - 512KB should be sufficient.
#
#   Setting the min, max, and default receive buffer (RX_WINDOW) size::
net.ipv4.tcp_rmem = 10240 87380 12582912

net.ipv4.tcp_mem = 10240 87380 12582912

EOF

FILENAME=10-ip_router_forwarding_state.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title: controls IP router forwarding
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:
# Reference:
#  - KVM Network Performance - Best Practices and Tuning Recommendations
#      https://www.ibm.com/downloads/cas/ZVJGQX8E
#  - https://www.uperf.org
#
# ip_forward - BOOLEAN
#        - 0 - disabled (default)
#        - not 0 - enabled
#
#        Forward Packets between interfaces.
#
#        This variable is special, its change resets all configuration
#        parameters to their default state (RFC1122 for hosts, RFC1812
#        for routers)

net.ipv4.ip_forward = 1

# conf/all/forwarding - BOOLEAN
#    Enable global IPv6 forwarding between all interfaces.
#
#    IPv4 and IPv6 work differently here; e.g. netfilter must be used
#    to control which interfaces may forward packets and which not.
#
#    This also sets all interfaces' Host/Router setting
#    'forwarding' to the specified value.  See below for details.
#
#    This referred to as global forwarding.

net.ipv4.conf.all.forwarding=1
net.ipv6.conf.all.forwarding=1

# ``conf/default/*``:
#  Change the interface-specific default settings.

net.ipv4.conf.default.forwarding=1
net.ipv6.conf.default.forwarding=1


# disable_ipv6 - BOOLEAN
#    Disable IPv6 operation.  If accept_dad is set to 2, this value
#    will be dynamically set to TRUE if DAD fails for the link-local
#    address.
#
#    Default: FALSE (enable IPv6 operation)
#
#    When this value is changed from 1 to 0 (IPv6 is being enabled),
#    it will dynamically create a link-local address on the given
#    interface and start Duplicate Address Detection, if necessary.
#
#    When this value is changed from 0 to 1 (IPv6 is being disabled),
#    it will dynamically delete all addresses and routes on the given
#    interface. From now on it will not possible to add addresses/routes
#    to the selected interface.

net.ipv6.conf.enp5s0.disable_ipv6 = 1

EOF

FILENAME=80-tcp_throughput_performance.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title: TCP throughput improvement
# Creator: ${CREATOR}
# Date: ${DATE}
# Reference:
#  - https://www.uperf.org
#
# tcp_allowed_congestion_control - STRING
#    Show/set the congestion control choices available to non-privileged
#    processes. The list is a subset of those listed in
#    tcp_available_congestion_control.
#
# The default algorithm for most kernel is 'reno'.
# After 13 variants of TCP congestion control, cubic is the best

net.ipv4.tcp_congestion_control = cubic

# tcp_fin_timeout parameter determines the length of
# time an orphaned (unreferenced) connection will wait
# before it is aborted at the local end.  This
# parameter is especially helpful for when something
# happens to the remote peer which prevents or
# excessively delays a response.  Since each socket
# used for connections consumes approxibately 1.5K
# bytes of memory, the kernel must pro-actively abort
# and purge dead or stale resources.
net.ipv4.tcp_fin_timeout = 1

# TCP controls small queue limits on per TCP-socket
# basis.  TCP tends to increase the data in-flight
# until loss notifications are received.  With aspects
# of TCP send auto-tuning, large amounts of data might
# get queued at the device on the local machine, which
# can adversely impact the latency for other streams.
# tcp_limit_output_bytes limits the number of bytes on
# a device to reduce the latency effects caused by a
# larger queue size.
# The default value is 262,144 bytes.  For workloads
# or environments where latency is higher priority
# than throughput, lower this value can improve
# latency.
net.ipv4.tcp_limit_output_bytes = 131072

# The normal TCP stack behavior is set to favor
# decisions that maximize network throughput.
# tcp_low_latency parameter, when set, tells TCP to
# instead make decisions that would prefer lower
# latency.
# The default value is 0(off).  For workloads or
# environments where latency is a higher priority, the
# recommended value is 1 (on).
net.ipv4.tcp_low_latency = 0

# tcp_max_tw_buckets specifies the maximum number of
# sockets in the "time-wait" state allowed to exist at
# any time.  If the maimum value is exceeded, sockets
# in the "time-wait" state are immediately destroyed
# and a warning is displayed.  This setting exists to
# thwart certain type of "Denial of Service" attacks.
# Care should be exercised before lowering this value.
# When changed, its value should be increased,
# especially when more memory has been added to the
# system or when the network demands are high and
# environment is less exposed to external threats.
net.ipv4.tcp_max_tw_buckets = 450000

# tcp_tw_reuse permits sockets in the "time-wait"
# state to be reused for new connections.  In high
# traffic environments, sockets are created and
# destroyed at very high rates.  This parameter, when
# set, allows "no longer neded" and "about to be
# destroyed" sockets to be used for new connections.
# When enabled, this parameter can bypass the
# allocation and initialization overhead normally
# associated with socket creation saving CPU cycles,
# system load and time.
net.ipv4.tcp_tw_reuse = 1

# We are not worried about 2GB rollover and recovering any lost packet before
net.ipv4.tcp_timestamps = 0

# We are not communicating through a satellite so TCP-SACK can go
net.ipv4.tcp_sack = 0
net.ipv4.tcp_dsack = 0

# tcp_max_syn_backlog - INTEGER
#    Maximal number of remembered connection requests (SYN_RECV),
#    which have not received an acknowledgment from connecting client.
#
#    This is a per-listener limit.
#
#    The minimal value is 128 for low memory machines, and it will
#    increase in proportion to the memory of machine.
#
#    If server suffers from overload, try increasing this number.
#
#    Remember to also check /proc/sys/net/core/somaxconn
#    A SYN_RECV request socket consumes about 304 bytes of memory.
#
# Setting large number of incoming TCP connection requests

net.ipv4.tcp_max_syn_backlog=3000

EOF

FILENAME=20-ip_routing_controls.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title: Do not accept IP source routing
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:
# Reference:
#
# Do not accept source routing
#
# accept_source_route - INTEGER
# Accept source routing (routing extension header).
#
#    - >= 0: Accept only routing header type 2.
#    - < 0: Do not accept routing header.
#
#    Default: 0

net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Controls source route verification
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Turn on protection for bad icmp error messages
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF


FILENAME=02-linux_kernel.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title: Minimize revealing internal kernel-based address pointer
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:
# Reference:
#

kernel.core_uses_pid = 1
kernel.kptr_restrict = 2

# 0=disable, 1=enable all
# Debian kernels have this set to 0 (disable the key)
# See https://www.kernel.org/doc/Documentation/sysrq.txt
# 0=disable, 1=enable all, >1 bitmask of sysrq functions
# See https://www.kernel.org/doc/html/latest/admin-guide/sysrq.html
# for what other values do
#kernel.sysrq=438
kernel.sysrq = 0
EOF

FILENAME=30-shared_memory_for_apps.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title: Increased share memory for PostgreSQL
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:
#   VPN and PostgreSQL
#
# Reference:
#

# Shared memory settings for PostgreSQL on Linux

# The settings here are upper limits; performance is not affected if the
# settings are larger than necessary. If other programs use shared memory as
# well, you will have to coordinate the size settings between them.

# Maximum size of a single shared memory segment in bytes
#kernel.shmmax = 33554432

# Maximum total size of all shared memory segments in pages (normally 4096 bytes)
#kernel.shmall = 2097152

# Added by hwdsl2 VPN script
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
EOF


FILENAME=31-bridge_vs_memory_cache.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title: Disable ntfiler for bridging
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:


# bridge-nf-call-ip6tables - BOOLEAN
#    - 1 : pass bridged IPv6 traffic to ip6tables' chains.
#    - 0 : disable this.
#
#    Default: 1

# net.bridge.bridge-nf-call-ip6tables = 0

# bridge-nf-call-iptables - BOOLEAN
#    - 1 : pass bridged IPv4 traffic to iptables' chains.
#    - 0 : disable this.
#
#    Default: 1

# net.bridge.bridge-nf-call-iptables = 0

# net.bridge.bridge-nf-call-arptables = 0

# bridge-nf-filter-vlan-tagged - BOOLEAN
#    - 1 : pass bridged vlan-tagged ARP/IP/IPv6 traffic to {arp,ip,ip6}tables.
#    - 0 : disable this.
#
#    Default: 0
net.bridge.bridge-nf-filter-vlan-tagged = 0

# bridge-nf-pass-vlan-input-dev - BOOLEAN
#    - 1: if bridge-nf-filter-vlan-tagged is enabled, try to find a vlan
#         interface on the bridge and set the netfilter input device to the
#         vlan. This allows use of e.g. "iptables -i br0.1" and makes the
#         REDIRECT target work with vlan-on-top-of-bridge interfaces.  When no
#         matching vlan interface is found, or this switch is off, the input
#         device is set to the bridge interface.
#
#    - 0: disable bridge netfilter vlan interface lookup.
#
#    Default: 0

net.bridge.bridge-nf-pass-vlan-input-dev = 0

#
# Reference:
# https://googleprojectzero.blogspot.com/2018/09/a-cache-invalidation-bug-in-linux.html
# https://security-tracker.debian.org/tracker/CVE-2018-17182

EOF



FILENAME=41-kernel_hardening.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title:  Restrict \`dmesg\` displaying sensitive kernel-based address pointers
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:
#
#   This toggle indicates whether unprivileged users
#   are prevented from using dmesg(8) to view
#   messages from the kernel's log buffer.  When
#   dmesg_restrict is set to (0) there are no
#   restrictions. When dmesg_restrict is set set
#   to (1), users must have CAP_SYSLOG to use dmesg(8).
#
#   The kernel config option CONFIG_SECURITY_DMESG_RESTRICT
#   sets the default value of dmesg_restrict.
#
# BEWARE: dmesg provides plenty of treasures for malware authors
#
kernel.dmesg_restrict = 1

EOF


FILENAME=49-router_mode.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title: Disable ICMP redirects & IPv6 router advertisements
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:
#   Disables the ICMP redirects (and flushes the IP route cache)

# This host IS a router
# however, we are selective in what we redirect
# therefore, we will not redirect ICMP on the public-side


net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.enp5s0.send_redirects=0
net.ipv4.conf.br0.send_redirects=1
net.ipv4.route.flush=1


# Make sure no one can alter the routing tables
# accept_redirects - BOOLEAN
#
#    Functional default:
#
#    - enabled if local forwarding is disabled.
#    - disabled if local forwarding is enabled.

net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv6.conf.enp5s0.accept_redirects=0
net.ipv6.conf.br0.accept_redirects=0

net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0

net.ipv4.conf.all.log_martians=1
net.ipv4.conf.default.log_martians=1

# icmp_echo_ignore_broadcasts - BOOLEAN
#    If set non-zero, then the kernel will ignore all ICMP ECHO and
#    TIMESTAMP requests sent to it via broadcast/multicast.
#
#    Default: 1

net.ipv4.icmp_echo_ignore_broadcasts=1

# Router advertisement
# accept_ra - INTEGER
#    Accept Router Advertisements; autoconfigure using them.
#
#    It also determines whether or not to transmit Router
#    Solicitations. If and only if the functional setting is to
#    accept Router Advertisements, Router Solicitations will be
#    transmitted.
#
#    Possible values are:
#
#    ==  ===========================================================
#     0  Do not accept Router Advertisements.
#     1  Accept Router Advertisements if forwarding is disabled.
#     2  Overrule forwarding behaviour. Accept Router Advertisements
#        even if forwarding is enabled.
#    ==  ===========================================================
#
#    Functional default:
#
#    - enabled if local forwarding is disabled.
#    - disabled if local forwarding is enabled.

net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.br0.accept_ra = 1

EOF


FILENAME=17-netfilter_nat_conntrack.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title: Enable connection tracker helper for nftables
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:
# Reference:
#

# Use with:
#  ipfilter -t raw -A PREROUTING -p udp -m udp --dport 5060 -j CT --helper sip
#  nft add rule filter filter c udp dport 5060 ct helper set "sip-5060"

net.netfilter.nf_conntrack_helper = 1

EOF


FILENAME=71-fs_hardlink_protect.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title:  Protect against creating/following links under certain conditions
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:
# Reference:
#  - https://www.kernel.org/doc/Documentation/sysctl/fs.txt
#

###################################################################
# Protected links
#
# Protects against creating or following links under certain conditions
# Debian kernels have both set to 1 (restricted)
fs.protected_fifos = 1
fs.protected_hardlinks = 1
fs.protected_regulars = 1
fs.protected_symlinks = 1
EOF

echo ""
echo "Done."
exit 0
