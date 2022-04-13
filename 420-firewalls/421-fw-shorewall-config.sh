#!/bin/bash
# File: 421-fw-shorewall-config.sh
# Title: Configure Shorewall firewall
#

echo "Configure Shorewall"
echo

source ./maintainer-fw-shorewall.sh
FILE_SETTINGS_FILESPEC="${BUILDROOT}/file-settings-shorewall-config.sh"
if [ "${BUILDROOT:0:1}" != '/' ]; then
  mkdir -p "$BUILDROOT"
else
  FILE_SETTING_PERFORM='true'
fi

flex_ckdir /etc
flex_ckdir /etc/shorewall

CHOICES_LIST_A=()
echo "1) If you have a desktop-type system with a single network interface"
echo "2) If you have a desktop-type system with a single network "
echo "       interface, pkg shorewall6"
echo "3) If you have a router with two network interfaces"
echo "4) If you have a router with three network interfaces"
read -rp "Enter in network configuration ID: " -ei1

case $REPLY in
  # If you have a desktop-type system with a single network interface
  1)
    cp /usr/share/doc/shorewall/examples/one-interface/* \
        "${BUILDROOT}/etc/shorewall/"
    ;;
  # If you have a desktop-type system with a single network
  #    interface, pkg shorewall6
  2)
    cp /usr/share/doc/shorewall6/examples/one-interface/* \
        "${BUILDROOT}/etc/shorewall6/"
    ;;
  # If you have a router with two network interfaces
  3)
    cp /usr/share/doc/shorewall/examples/two-interfaces/* \
        "${BUILDROOT}/etc/shorewall/"
    ;;
  # If you have a router with three network interfaces
  4)
    cp /usr/share/doc/shorewall/examples/three-interfaces/* \
        "${BUILDROOT}/etc/shorewall/"
    ;;
esac

pushd .
cd "${BUILDROOT}/etc/shorewall"
gunzip -f shorewall.conf.annotated.gz
gunzip -f shorewall.conf.gz
popd

SHOREWALL_CAPABILITIES="/tmp/capabilities"
if [ ! -f "${SHOREWALL_CAPABILITIES}" ]; then
  echo "Ummmm, shorewall capabilities file is missing."
  echo "Requires 'sudo shorewall show capabilities > /tmp/capabilities'"
  read -rp "Execute above? (N/y): " -ein
  REPLY="${REPLY:0:1}"
  if [ -z "$REPLY" ] || [ "$REPLY" != 'y' ]; then
    echo "Aborted."
    exit 3
  fi
  sudo /usr/sbin/shorewall show -f capabilities > "$SHOREWALL_CAPABILITIES"
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "Error in shorewall: errno $retsts; aborted."
    exit $retsts
  fi
fi
if [ -f "${SHOREWALL_CAPABILITIES}" ]; then
  # Go where the 'capabilities' file is located
  orig_cd="$(echo $PWD)"
  cd /tmp
  shorewall check -e "${orig_cd}/${BUILDROOT}/etc/shorewall"
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "Shorewall syntax check failed."
    exit $retsts
  fi
  popd
else
  echo "As root, execute:"
  echo
  echo "  shorewall check ${BUILDROOT}/etc/shorewall"
fi
echo

echo "Now you can edit the firewall rules in /etc/shorewall/rules file."
echo "Then do:"
echo "  shorewall check"
echo "  shorewall start"
echo "  shorewall stop"
echo "or execute:"
echo "  shorewall clear"
echo "to go back to non-firewall state".
echo
echo "Done."
