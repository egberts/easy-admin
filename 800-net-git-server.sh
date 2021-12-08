#!/bin/bash
# File: 800-net-git-server.sh
# Title: Git server daemon
# Description:
#  Involves using 'git-daemon' (as part of 'git-core') as a Git server.
#
#  Check for any '/usr/lib/git-core/git-daemon'
#  Check for any systemd 'git-daemon' service
#  Check for 'gitdaemon' user/group
#  Check for any 'authorized_keys'  (might need to be a separate script here)
#  Opens port 'git' 9481/tcp
#  Uses /var/lib/git and its subdirectory(s)
#
# References:
#  * https://egbert.net/blog/articles/fine-tuning-ssh-authorized_keys.html
#
echo "Git server daemon, and security hardening..."
echo ""

if [ "$USER" != "root" ]; then
  echo "$0: this script works best in root-mode"
  echo "Might want to review the script firstly before running"
  echo "Aborted."
  exit 11
fi

BUILDROOT="${BUILDROOT:-build}"  # default is relative 'build/' directory name

prefix="${prefix:-/usr}"
sysconfdir="${sysconfdir:-/etc}"
bindir="$prefix/bin"
libdir="$prefix/lib"

BIN_NAME="git-daemon"
PKG_NAME="git-daemon"
DIR_NAME="git-daemon"

# You won't find this daemon executable using 'which'/'whereis'
GIT_CORE_LIB_DIRSPEC="$libdir/git-core"
GIT_DAEMON_EXECBIN_FILESPEC="$GIT_CORE_LIB_DIRSPEC/$BIN_NAME"


if [ -z "$GIT_DAEMON_EXECBIN_FILESPEC" ]; then
  echo "Does not look like GIT_DAEMON_BIN is found among the following paths:"
  echo "Package git-daemon-run or git-daemon-sysvinit is probably not installed."
  echo "PATH=$PATH"
  echo "Aborted."
  exit 9
fi

# Check if '/etc/default/git-daemon' exist
ETC_DEFAULT_DIRSPEC="$sysconfdir/default"
ETC_DEFAULT_GITDAEMON_FILENAME="$PKG_NAME"
ETC_DEFAULT_GITDAEMON_FILESPEC="$ETC_DEFAULT_DIRSPEC/$PKG_NAME"

if [ ! -e "$ETC_DEFAULT_GITDAEMON_FILESPEC" ]; then
  echo "Not possible to know what USER name that 'git-daemon' uses; aborted."
  exit 3
fi

# Obtain USER from /etc/default/git-daemon
source /etc/default/git-daemon
if [ -z "$GIT_DAEMON_USER" ]; then
  echo "Default /etc/default/git-daemon did not define GIT_DAEMON_USER envar."
  echo "aborted."
  exit 3
fi

# Check if requested USER is also in /etc/passwd
id $GIT_DAEMON_USER
retsts=$?
if [ "$retsts" -ne 0 ]; then
  echo "Requested Git username '$GIT_DAEMON_USER' is not found in /etc/passwd"
  echo "Aborted."
  exit 11
fi

# Need to check the repository directory
if [ -z "$GIT_DAEMON_DIRECTORY" ]; then
  echo "Git repo directory (GIT_DAEMON_DIRECTORY) not defined."
  echo "Aborted."
  exit 3
fi

if [ ! -d "$GIT_DAEMON_DIRECTORY" ]; then
  echo "Git repo ($GIT_DAEMON_DIRECTORY) is not a directory.  Aborted."
  exit 11
fi
echo ""

# Check if export is wanted via /var/lib/git/git-daemon-export-ok token file.
GIT_DAEMON_EXPORT_OK_FILESPEC="$GIT_DAEMON_DIRECTORY/git-daemon-export-ok"
if [ -f "$GIT_DAEMON_EXPORT_OK_FILESPEC" ]; then
  echo "WARNING: Git repo are exportable, as well as importable!"
  read -rp "Do you still want export capability for this Git repo? (N/y): " -eiN
  REPLY="$(echo "${REPLY:0:1}" | awk '{ print tolower($1) }')"
  if [ -z "$REPLY" ] || [ "$REPLY" == 'n' ]; then
    echo "Removing $GIT_DAEMON_EXPORT_OK_FILESPEC ..."
    rm -f "$GIT_DAEMON_EXPORT_OK_FILESPEC"
    retsts=$?
    if [ $retsts -ne 0 ]; then
      echo "Deletion of $GIT_DAEMON_EXPORT_OK_FILESPEC failed."
      echo "Aborted."
      exit 3
    fi
  fi
fi

# Probably should lock down the directory???  Even if its publically available?
#
# Who would own the Git directory in /var/lib/git?
#    gitdaemon
#       or
#    git

# replace systemd git-daemon service file?

GD_OVERRIDE_CONF="override-hardened.conf"
SYSD_GD_DROPIN_DIRSPEC="/etc/systemd/system/git-daemon.d"
SYSD_GD_DROPIN_FILESPEC="${SYSD_GD_DROPIN_DIRSPEC}/$GD_OVERRIDE_CONF"

# systemd does not get 'chrooted' so we dont use CHROOT_DIR envar
mkdir -p "${BUILDROOT}$SYSD_GD_DROPIN_DIRSPEC"
cat << EOF | tee "${BUILDROOT}$SYSD_GD_DROPIN_FILESPEC" >/dev/null
#
# File: ${GD_OVERRIDE_CONF}
# Path: ${SYSD_GD_DROPIN_DIRSPEC}
# Creator: $(basename "$0")
# Date: $(date)
# Description:
#  Some untested settings as reported by \`systemd-analyze security git-daemon\`
#

[Unit]
PrivateNetwork=True

# NAME  DESCRIPTION  EXPOSURE
# ✗ User=/DynamicUser=        Service runs as root user         0.4
# ✗ CapabilityBoundingSet=~CAP_SET(UID|GID|PCAP)   Service may change UID/GID identities/capabilities      0.3
# ✗ CapabilityBoundingSet=~CAP_SYS_ADMIN    Service has administrator privileges        0.3
# ✗ CapabilityBoundingSet=~CAP_SYS_PTRACE      Service has ptrace() debugging abilities       0.3
# ✗ RestrictAddressFamilies=~AF_(INET|INET6)    Service may allocate Internet sockets       0.3
# ✗ RestrictNamespaces=~CLONE_NEWUSER      Service may create user namespaces         0.3
# ✗ RestrictAddressFamilies=~…       Service may allocate exotic sockets        0.3
# ✗ CapabilityBoundingSet=~CAP_(CHOWN|FSETID|SETFCAP)    Service may change file ownership/access mode/capabilities unrestricted  0.2
# ✗ CapabilityBoundingSet=~CAP_(DAC_*|FOWNER|IPC_OWNER)  Service may override UNIX file/IPC permission checks     0.2
# ✗ CapabilityBoundingSet=~CAP_NET_ADMIN    Service has network configuration privileges      0.2
# ✗ CapabilityBoundingSet=~CAP_SYS_MODULE      Service may load kernel modules         0.2
# ✗ CapabilityBoundingSet=~CAP_SYS_RAWIO    Service has raw I/O access          0.2
# ✗ CapabilityBoundingSet=~CAP_SYS_TIME     Service processes may change the system clock      0.2
# ✗ DeviceAllow=        Service has no device ACL         0.2
# ✗ IPAddressDeny=         Service does not define an IP address allow list      0.2
# ✓ KeyringMode=        Service doesn't share key material with other services
# ✗ NoNewPrivileges=        Service processes may acquire new privileges      0.2
# ✓ NotifyAccess=          Service child processes cannot alter service state
# ✗ PrivateDevices=        Service potentially has access to hardware devices      0.2
# ✗ PrivateMounts=         Service may install system mounts        0.2
# ✗ PrivateTmp=         Service has access to other software's temporary files      0.2
# ✗ PrivateUsers=          Service has access to other users        0.2
# ✗ ProtectClock=          Service may write to the hardware clock or system clock     0.2
# ✗ ProtectControlGroups=        Service may modify the control group file system      0.2
# ✗ ProtectHome=        Service has full access to home directories       0.2
# ✗ ProtectKernelLogs=        Service may read from or write to the kernel log ring buffer    0.2
# ✗ ProtectKernelModules=        Service may load or read kernel modules        0.2
# ✗ ProtectKernelTunables=        Service may alter kernel tunables        0.2
# ✗ ProtectProc=        Service has full access to process tree (/proc hidepid=)    0.2
# ✗ ProtectSystem=         Service has full access to the OS file hierarchy      0.2
##  ✗ RestrictAddressFamilies=~AF_PACKET      Service may allocate packet sockets        0.2
# ✗ RestrictSUIDSGID=         Service may create SUID/SGID files         0.2
# ✗ SystemCallArchitectures=      Service may execute system calls with all ABIs       0.2
# ✗ SystemCallFilter=~@clock      Service does not filter system calls        0.2
# ✗ SystemCallFilter=~@debug      Service does not filter system calls        0.2
# ✗ SystemCallFilter=~@module        Service does not filter system calls        0.2
# ✗ SystemCallFilter=~@mount      Service does not filter system calls        0.2
# ✗ SystemCallFilter=~@raw-io        Service does not filter system calls        0.2
# ✗ SystemCallFilter=~@reboot        Service does not filter system calls        0.2
# ✗ SystemCallFilter=~@swap       Service does not filter system calls        0.2
# ✗ SystemCallFilter=~@privileged       Service does not filter system calls        0.2
# ✗ SystemCallFilter=~@resources      Service does not filter system calls        0.2
# ✓ AmbientCapabilities=       Service process does not receive ambient capabilities
# ✗ CapabilityBoundingSet=~CAP_AUDIT_*      Service has audit subsystem access         0.1
# ✗ CapabilityBoundingSet=~CAP_KILL      Service may send UNIX signals to arbitrary processes     0.1
# ✗ CapabilityBoundingSet=~CAP_MKNOD     Service may create device nodes         0.1
# ✗ CapabilityBoundingSet=~CAP_NET_(BIND_SERVICE|BROADCAST|RAW) Service has elevated networking privileges        0.1
# ✗ CapabilityBoundingSet=~CAP_SYSLOG      Service has access to kernel logging        0.1
# ✗ CapabilityBoundingSet=~CAP_SYS_(NICE|RESOURCE)    Service has privileges to change resource use parameters    0.1
# ✗ RestrictNamespaces=~CLONE_NEWCGROUP     Service may create cgroup namespaces        0.1
# ✗ RestrictNamespaces=~CLONE_NEWIPC     Service may create IPC namespaces        0.1
# ✗ RestrictNamespaces=~CLONE_NEWNET     Service may create network namespaces       0.1
# ✗ RestrictNamespaces=~CLONE_NEWNS      Service may create file system namespaces      0.1
# ✗ RestrictNamespaces=~CLONE_NEWPID     Service may create process namespaces       0.1
# ✗ RestrictRealtime=         Service may acquire realtime scheduling        0.1
# ✗ SystemCallFilter=~@cpu-emulation     Service does not filter system calls        0.1
# ✗ SystemCallFilter=~@obsolete      Service does not filter system calls        0.1
# ✗ RestrictAddressFamilies=~AF_NETLINK     Service may allocate netlink sockets        0.1
# ✗ RootDirectory=/RootImage=        Service runs within the host's root directory      0.1
#   SupplementaryGroups=       Service runs as root, option does not matter
# ✗ CapabilityBoundingSet=~CAP_MAC_*     Service may adjust SMACK MAC         0.1
# ✗ CapabilityBoundingSet=~CAP_SYS_BOOT     Service may issue reboot()          0.1
# ✓ Delegate=          Service does not maintain its own delegated control group subtree
# ✗ LockPersonality=        Service may change ABI personality         0.1
# ✗ MemoryDenyWriteExecute=       Service may create writable executable memory mappings      0.1
#   RemoveIPC=          Service runs as root, option does not apply
# ✗ RestrictNamespaces=~CLONE_NEWUTS     Service may create hostname namespaces        0.1
# ✗ UMask=          Files created by service are world-readable by default      0.1
# ✗ CapabilityBoundingSet=~CAP_LINUX_IMMUTABLE    Service may mark files immutable        0.1
# ✗ CapabilityBoundingSet=~CAP_IPC_LOCK     Service may lock memory into RAM        0.1
# ✗ CapabilityBoundingSet=~CAP_SYS_CHROOT      Service may issue chroot()          0.1
# ✗ ProtectHostname=        Service may change system host/domainname      0.1
# ✗ CapabilityBoundingSet=~CAP_BLOCK_SUSPEND    Service may establish wake locks        0.1
# ✗ CapabilityBoundingSet=~CAP_LEASE     Service may create file leases          0.1
# ✗ CapabilityBoundingSet=~CAP_SYS_PACCT    Service may use acct()           0.1
# ✗ CapabilityBoundingSet=~CAP_SYS_TTY_CONFIG     Service may issue vhangup()          0.1
# ✗ CapabilityBoundingSet=~CAP_WAKE_ALARM      Service may program timers that wake up the system      0.1
# ✗ RestrictAddressFamilies=~AF_UNIX     Service may allocate local sockets         0.1
# ✗ ProcSubset=         Service has full access to non-process /proc files (/proc subset=)    0.1
#
# → Overall exposure level for git-daemon.service: 9.6 UNSAFE 😨

EOF
echo "Wrote ${BUILDROOT}$SYSD_GD_DROPIN_FILESPEC"
echo "NOTE: You may want to edit this file"
echo ""
echo "Might also want to modify /home/*/.ssh/authorized_keys
#  * https://egbert.net/blog/articles/fine-tuning-ssh-authorized_keys.html
echo "Done."
exit 0
