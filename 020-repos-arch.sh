#!/bin/bash
#
# OS: ArchLinux
# Kernel: 5.10.46
#
# Everything except the Linux kernel

echo "For Arch Linux, Kernel 5.15.46 requires some more packages"


pacman -S bind
pacman -S chrony
pacman -S openssh
pacman -S dhcp
pacman -S nftables

pacman -S fontconfig

