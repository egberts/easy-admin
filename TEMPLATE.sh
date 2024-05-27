#!/bin/bash
# File: 020-repos-debian-11.sh
# Title:  Install everything related to Debian 11
# Description:
#   TBD
#
# Privilege required: sudo root
# OS: Debian
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
# Environment Variables (read):
#   BUILDROOT - set to '/' to actually install directly into your filesystem
#
# Environment Variables (created):
#   none
#
# Prerequisites (package name):
#   apt (apt)
#   awk (mawk)
#   basename (coreutils)
#   cat (coreutils)
#   chown (coreutils)
#   chmod (coreutils)
#   curl (curl)
#   date (coreutils)
#   dd (coreutils)
#   dig (bind9-dnsutils)
#   dirname (coreutils)
#   dnf (dnf)
#   dpkg (dpkg)
#   find (findutils)
#   git (git)
#   grep (grep)
#   grub (grub)
#   head (coreutils)
#   ipcalc-ng (ipcalc-ng)
#   ip (iproute2)
#   lsb-release (lsb_release)
#   mkdir (coreutils)
#   mount (mount)
#   nmcli (nmcli)
#   nslookup (bind9-dnsutils)
#   realpath (coreutils)
#   rm (coreutils)
#   sed (sed)
#   sort (coreutils)
#   stat (coreutils)
#   sudo (sudo)
#   systemctl (systemd) - optional
#   tail (coreutils)
#   tee (coreutils)
#   touch (coreutils)
#   tr (coreutils)
#   unzip (unzip)
#   wget (wget)
#   whereis (util-linux)
#   wc (coreutils)
#   wg (wireguard-tools)
#   xargs (findutils)
#
# Detailed Design
#
# References:
#   https://help.ubuntu.com/community/Grub2/Passwords
#   CIS Security Debian 10 Benchmark, 1.0, 2020-02-13
#
