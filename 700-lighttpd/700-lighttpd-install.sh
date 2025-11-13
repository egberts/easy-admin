#
# File: 700-lighttpd-install.sh
# Title: Install LigHTTPd web server

source ./maintainer-lighttpd.sh

case $ID in
  debian)
    apt install $package_tarname
    ;;
  devuan)
    apt install $package_tarname
    ;;
  fedora)
    dnf install $package_tarname
    ;;
  redhat)
    dnf install $package_tarname
    ;;
  centos)
    dnf install $package_tarname
    ;;
  rockyos)
    dnf install $package_tarname
    ;;
  arch)
    pacman -S $package_tarname
    ;;
esac
