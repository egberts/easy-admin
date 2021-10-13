#!/bin/bash

IPSET_NAME="timer"
TMP_IPSET_NAME="$IPSET_NAME-tmp"

IPSET=/sbin/ipset

# Read the mac-timed-access file
k=1
MACS=''
while read line;do
        echo "Line # $k: $line"
        MACS="$MACS $line "
        ((k++))
done < mac-timed-access
echo $MACS
# Check if downloaded anything
if [ -n "$MACS" ]; then
  # Create lists, ignore errors if already exist
  $IPSET -! create $IPSET_NAME hash:mac
  RETSTS=$?
  if [ $RETSTS -eq 0 ]; then
       
    $IPSET -! create $TMP_IPSET_NAME hash:mac
    RETSTS=$?
    if [ $RETSTS -eq 0 ]; then
      $IPSET flush $TMP_IPSET_NAME

      # Add nodes to the tmp list
      for MAC in $MACS; do
          $IPSET -! add $TMP_IPSET_NAME $MAC
      done

      # Swap the lists (i.e. update) and delete the tmp one
      $IPSET swap $TMP_IPSET_NAME $IPSET_NAME
      $IPSET destroy $TMP_IPSET_NAME
    fi
  fi
  if [ $RETSTS -ne 0 ]; then
    echo "Ouchy, ouch!"
    # try again using iptables ebridge?
  fi
else
        echo "Failed to read timed-mac-access file...'"
fi
