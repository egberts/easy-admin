#!/bin/bash
# File: 114-cis-aide.sh
# Title: Install AIDE and configure it
#

dpkg -s aide >/dev/null
RETSTS=$?
if [ "$RETSTS" -ne 0 ]; then
  echo "AIDE package is not installed."
  echo "Aborted."
  exit 254
  sudo apt install aide aide-common
fi

echo "Initializing AIDE database..."
sudo aideinit --yes
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
  echo "Error during initialization of AIDE database. Errcode: $RETSTS"
  exit $RETSTS
fi
echo "aide -i RETSTS: $RETSTS"
echo "Done."
