#!/bin/bash

source os-distro.sh

case $ID in

  debian)
    IMICRO_INSTALLED="$(apt search intel-microcode 2>/dev/null|grep intel-microcode|grep -c installed)"
    WMICRO_INSTALLED="$(apt search firmware-iwlwifi 2>/dev/null|grep firmware-iwlwifi|grep -c installed)"
    if [ "$IMICRO_INSTALLED" -eq 0 ]; then
      sudo apt install intel-microcode
    fi
    if [ "$WMICRO_INSTALLED" -eq 0 ]; then
      sudo apt install firmware-iwlwifi
    fi
    ;;

  fedora)
    dnf install microcode_ctl
    ;;

echo "Latest microcodes installed."
