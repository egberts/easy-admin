#!/bin/bash

IPSET_NAME="timer"
TMP_IPSET_NAME="$IPSET_NAME-tmp"

IPSET=/sbin/ipset

        # Create lists, ignore errors if already exist
        $IPSET -! create $IPSET_NAME hash:mac
        $IPSET -! create $TMP_IPSET_NAME hash:mac
        $IPSET flush $TMP_IPSET_NAME

        # Swap the lists (i.e. update) and delete the tmp one
        $IPSET swap $TMP_IPSET_NAME $IPSET_NAME
        $IPSET destroy $TMP_IPSET_NAME
