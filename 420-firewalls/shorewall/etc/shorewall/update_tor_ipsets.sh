#!/bin/sh

exit 0

IPSET_NAME="tor"
TMP_IPSET_NAME="$IPSET_NAME-tmp"

IPSET=/sbin/ipset

TORPROJECTALIVE=`ping -W1 -c1 check.torproject.org`
if [ $? -ne 0 ]; then
    wall "check.torproject.org is offline"
    exit 0
fi

# Download the Tor exit node list
NODES=`wget -q -O- -T 60 https://check.torproject.org/exit-addresses | grep -i ExitAddress | cut -f 2 -d ' '`

# Check if downloaded anything
if [ -n "$NODES" ]; then
        # Create lists, ignore errors if already exist
        $IPSET -! create $IPSET_NAME iphash
        $IPSET -! create $TMP_IPSET_NAME iphash
        $IPSET flush $TMP_IPSET_NAME

        # Add nodes to the tmp list
        for IP in $NODES; do
                $IPSET -! add $TMP_IPSET_NAME $IP
        done

        # Swap the lists (i.e. update) and delete the tmp one
        $IPSET swap $TMP_IPSET_NAME $IPSET_NAME
        $IPSET destroy $TMP_IPSET_NAME
else
        echo "Failed to download/parse the Tor node list..."
fi
