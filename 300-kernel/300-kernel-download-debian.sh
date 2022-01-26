#!/bin/bash
# File: 300-kernel-download.sh
# Title: Download Linux kernel
#
# To get original non-Debian Linux kernel
#    apt download linux-source-5.10
#    dpkg -i linux-source-5.10*.deb
#
#    # stored  into /usr/src/linux-source-5.10*.tgz
#
#    tar xvfJ /usr/src/linux-source*.tgz
#    # writes into ./linux-5.10
#

# Installs into local directory
apt source --download linux-source
apt source --download linux-headers-amd64
apt source --download linux-config-5.10

# filename format: linux-5.10.92_5.10.92.orig.tar.gz

