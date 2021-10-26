#!/bin/bash
# File: 500-dns-bind9-install.sh
# Title: Install ISC Bind9 server

sudo apt install bind9 bind9-dnsutils bind9-doc

echo "Installing named-checkconf Bind9 syntax checker tool..."
sudo apt install bind9-utils

echo "Installing 'host -A mydomain' command ..."
sudo apt install bind9-host

# Development packages requires
# apt install libtool-bin
# apt install libcap-dev
