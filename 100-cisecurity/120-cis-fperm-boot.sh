#!/bin/bash
# File: 120-cis-fperm-boot.sh
# Title: Knock off group-other file permissions from GRUB boot menu

sudo chown root:root /boot/grub/grub.cfg
sudo chmod og-rwx    /boot/grub/grub.cfg
