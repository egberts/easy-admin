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
# Environment Variables:
#   BUILDROOT - set to '/' to actually install directly into your filesystem
#
# Prerequisites (package name):
#   apt (apt)
#   awk (mawk)
#   cat (coreutils)
#   chown (coreutils)
#   chmod (coreutils)
#   curl (curl)
#   dd (coreutils)
#   dig (bind9-dnsutils)
#   dnf (dnf)
#   dpkg (dpkg)
#   find (findutils)
#   git (git)
#   grep (grep)
#   grub (grub)
#   head (coreutils)
#   ipcalc-ng
#   ip (iproute2)
#   lsb-release (lsb_release)
#   mkdir (coreutils)
#   mount (mount)
#   nmcli (nmcli)
#   nslookup (bind9-dnsutils)
#   rm (coreutils)
#   sed (sed)
#   sort (coreutils)
#   sudo (sudo)
#   systemctl (systemd) - optional
#   tee (coreutils)
#   touch (coreutils)
#   unzip (unzip)
#   wget (wget)
#   whereis (util-linux)
#   wg (wireguard-tools)
#   xargs (findutils)
#
# Detailed Design
#
# References:
#   https://help.ubuntu.com/community/Grub2/Passwords
#   CIS Security Debian 10 Benchmark, 1.0, 2020-02-13
#
