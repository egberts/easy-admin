#!/bin/bash
# File: 020-repos-debian-11.sh
# Title:  Install everything related to Debian 11
#
# Privilege required: sudo root
# OS: Debian 11
# Kernel: Linux
#
# Files impacted:
#  read   - /boot/grub2
#           /etc/default/grub
#  create - none
#  modify - none
#  delete - none
#
# Note:
#   This is a bizarre use of Microsoft DotNet for GUI-less hosts.
#   Made NOT an executable due to lack of security review
#
# Environment Variables:
#   BUILDROOT - set to '/' to actually install directly into your filesystem
#
# Prerequisites:
#   bind9-dnsutils (/usr/bin/dig)
#   coreutils (tee, chown, chmod, touch)
#   dig (bind9-dnsutils)
#   findutils (xargs)???
#   grep (grep)
#   grub (grub)
#   gawk (awk)
#   ipcalc-ng
#   iproute2 (/sbin/ip)
#   lsb-release (lsb_release)
#   mount (mount)
#   nmcli (nmcli)
#   nslookup (bind9-dnsutils)
#   sed (sed)
#   sudo (sudo)
#   systemctl (systemd) - optional
#   util-linux (whereis)
#   wireguard-tools
#
# Detailed Design
#
# References:
#   https://help.ubuntu.com/community/Grub2/Passwords
#   CIS Security Debian 10 Benchmark, 1.0, 2020-02-13
#
