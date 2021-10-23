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
  echo "ERROR: /etc/sysctl.conf exists; delete or rename it away"
  exit 9
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
FILENAME=randomize_va_space.conf
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

FILENAME=net_core_netdev_max_backlog.conf
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
# Reference:
#  - KVM Network Performance - Best Practices and Tuning Recommendations
#      https://www.ibm.com/downloads/cas/ZVJGQX8E
#
net.core.netdev_max_backlog = 2500
EOF

FILENAME=memory_usage_network_stack.conf
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
net.ipv4.tcp_rmem = 10240 87380 12582912
EOF

FILENAME=ip_router_forwarding_state.conf
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
net.ipv4.ip_forward = 1

net.ipv4.conf.all.forwarding=1
net.ipv4.conf.default.forwarding=1

net.ipv6.conf.all.forwarding=1
net.ipv6.conf.default.forwarding=1

net.ipv6.conf.enp5s0.disable_ipv6 = 1
EOF

FILENAME=tcp_throughput_performance.conf
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
net.ipv4.tcp_sacks = 0
EOF

FILENAME=ip_routing_controls.conf
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


FILENAME=linux_kernel.conf
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

FILENAME=ipv6.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title:  Disable IPv6
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:
# Reference:
#

# DO NOT ENABLE UNTIL IPv6 Firewall is in place
#
net.ipv6.conf.enp5s0.disable_ipv6 = 1
EOF


FILENAME=shared_memory_for_apps.conf
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


FILENAME=bridge_vs_memory_cache.conf
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
# Reference:
#

# net.bridge.bridge-nf-call-ip6tables = 0
# net.bridge.bridge-nf-call-iptables = 0
# net.bridge.bridge-nf-call-arptables = 0
#
# https://googleprojectzero.blogspot.com/2018/09/a-cache-invalidation-bug-in-linux.html
# https://security-tracker.debian.org/tracker/CVE-2018-17182
EOF



FILENAME=kernel_hardening.conf
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

# dmesg provides plenty of treasures for malware
kernel.dmesg_restrict = 1
fs.suid_dumpable = 0

EOF


FILENAME=router_mode.conf
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
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv6.conf.enp5s0.accept_redirects=0
net.ipv6.conf.br0.accept_redirects=0

net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0

net.ipv4.conf.all.log_martians=1
net.ipv4.conf.default.log_martians=1

net.ipv4.icmp_echo_ignore_broadcasts=1

# Router advertisement
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.br0.accept_ra = 1

EOF


FILENAME=binfmt.conf
SYSCTLD_DROPIN_FILESPEC="$SYSCTLD_DIRPATH/$FILENAME"
echo "Creating $SYSCTLD_DROPIN_FILESPEC file..."
cat << EOF | sudo tee "$SYSCTLD_DROPIN_FILESPEC" >/dev/null
#
# File: ${FILENAME}
# Path: ${SYSCTLD_DIRPATH}
# Title:  Disable mounting of BINFMT
# Creator: ${CREATOR}
# Date: ${DATE}
# Description:
#

# systemctl mask proc-sys-fs-binfmt_misc.automount

fs.binfmt_misc.status = disable
fs.binfmt_misc.status = 0
EOF


FILENAME=netfilter_nat_conntrack.conf
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


FILENAME=fs_hardlink_protect.conf
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
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF

echo ""
echo "Done."
exit 0
