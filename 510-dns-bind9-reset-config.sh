#!/bin/bash
# File: 510-dns-bind9-reset-config.sh
# Title:  Restart Bind9 configuration from scratch

echo "Clearing out prior settings in /tmp/named.conf"
rm -rf /tmp/named.conf

echo "Creating a new /tmp/named.conf directory..."
mkdir /tmp/named.conf

echo ""
echo "Done."
exit 0

