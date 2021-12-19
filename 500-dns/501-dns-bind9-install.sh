#!/bin/bash
# File: 500-dns-bind9-install.sh
# Title: Install ISC Bind9 server

source ./os-distro.sh

case $ID in
  debian)
    apt install bind9 bind9-dnsutils bind9-doc
    echo "Installing named-checkconf Bind9 syntax checker tool..."
    apt install bind9-utils
    echo "Installing 'host -A mydomain' command ..."
    apt install bind9-host
    # Development packages requires
    # apt install libtool-bin
    # apt install libcap-dev
    ;;
  redhat)
    dnf install bind-libs
    dnf install bind
    dnf install bind-dlz-filesystem
    # dnf install bind-chroot
    # dnf install bind-doc
    ;;
  centos)
    dnf install bind-libs
    dnf install bind
    dnf install bind-dlz-filesystem
    # dnf install bind-chroot
    # dnf install bind-doc
    ;;
  fedora)
    dnf install bind-dnssec-doc
    dnf install bind-libs
    dnf install python3-bind
    dnf install bind
    dnf install bind-dnssec-utils
    dnf install bind-dlz-filesystem
    # dnf install bind-chroot
    # dnf -y install bind-doc --setopt=install_weak_deps=False
    ;;
esac

