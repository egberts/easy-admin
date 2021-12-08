#!/bin/bash
# File: 408-net-network-manager-desktop.sh
# Title: Ensure desktop icon for NetworkManager
#
# Design:
#    Obtain desktop installed (GNOME, KDE, Xorg)
#

# GNOME:
#    GNOME already has built-in tool to NetworkManager settings
#    GNOME/Keyring is good for storing connector secrets
#
# KDE:
#    Plasma has 'plasma-nm' package
#
# Xorg:
#   Xorg has GTK3 front-end
#   Create 'nmgui'
#       #!/bin/sh
#       APP_INDICATOR_ENABLE='--indicator'
#       NOTIFICATION_DISABLE='--no-agent'
#       nm-applet $APP_INDICATOR_ENABLE $NOTIFICATION_DISABLE 2>&1 >/dev/null &
#       stalonetray 2>&1 >/dev/null
#       killall nm-applet
#   .Desktop file for autostart
#       Exec=nm-applet --no-agent


# Make available to other users: FALSE/OFF/DISABLE
#  - Enabling 'make available...' allows its connector secrets totally exposed


