#!/bin/bash
# File: 020-repos-arch.sh
# Title: Install what is needed for Arch distro
# OS: ArchLinux
# Kernel: 5.10.46
# Description
#   Install everything except the Linux kernel
#
# Privilege required: root
#
# Files impacted:
#  read   - /usr/bin/pacman
#  create - (various installed files)
#  modify - none
#  delete - none
#
# Environment Variables:
#   none
#
# Prerequisites:
#   pacman
#


echo "For Arch Linux, Kernel 5.15.46 requires some more packages"
echo

pacman -S bind
pacman -S chrony
pacman -S openssh
pacman -S dhcp
pacman -S nftables
pacman -S fontconfig
echo

echo "Done."
