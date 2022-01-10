#!/bin/bash
# File: 300-kernel-download-archlinux.sh
# Title: Download Linux kernel
#
# To get original non-Debian Linux kernel
#
#

pacman -S --needed base-devel
pacman -S pahole  # used by Linux kernel 'make bzImage'

pacman -S linux

# header files?
# config file?


