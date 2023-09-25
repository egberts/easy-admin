#!/bin/bash
# File: 100-cis-packages-remove.sh
# Title: Remove packages as CIS Benchmark recommends
#

echo "CIS Benchmark Recommendation for removals of Debian packages"
echo ""

read -rp "Type in 'continue' and ENTER to continue: "
if [ "$REPLY" != 'continue' ]; then
  echo "Aborted."
  exit 254
fi

sudo systemctl --now disable autofs
sudo apt purge autofs
sudo apt purge xinetd
sudo apt purge openbsd-inetd
sudo apt purge nfs-common

echo "Done."
exit 0
