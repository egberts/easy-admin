#!/bin/bash
# File: 300-kernel-download.sh
# Title: Download Linux kernel
#
# To get original non-Debian Linux kernel
#    apt download linux-source-6.1
#    dpkg -i linux-source-6.1*.deb
#
#    # stored  into /usr/src/linux-source-6.1*.tgz
#
#    tar xvfJ /usr/src/linux-source*.tgz
#    # writes into ./linux-6.1
#

apt source build-essential
apt source libncurses5-dev
apt source bc kmod cpio
apt source bison flex
apt source libncurses5-dev
apt source libelf-dev
apt source libssl-dev
apt source dwarves

# Installs into local directory
apt source --download linux-source
apt source --download linux-headers-amd64
apt source --download linux-config-6.1

# filename format: linux-.10.92_5.10.92.orig.tar.gz

