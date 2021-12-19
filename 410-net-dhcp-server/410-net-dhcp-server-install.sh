#
# File: 410-dhcp-server-install.sh
# Title: Install ISC DHCP server

source ./os-distro.sh

case $ID in
  debian)
    apt install isc-dhcp-server
    ;;
  fedora)
    dnf install dhcp-server
    ;;
  redhat)
    dnf install dhcp-server
    ;;
  centos)
    dnf install dhcp-server
    ;;
esac
