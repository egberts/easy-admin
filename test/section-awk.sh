#!/bin/bash
#
# Repo: https://unix.stackexchange.com/questions/137643/editing-ini-like-files-with-a-script

#
# Here are a few script examples. These are 
# bare minimum and don't bother with error checking, 
# command line options, etc. I've indicated whether 
# I've run the script myself to verify its correctness.

# awk

# This script is more Bash and *nix friendly and uses a common utility of *nix OS's, awk. This script is tested.

#!/usr/bin/env awk
# filename: ~/config.awk

BEGIN {
    in_agent_section=0;
    is_host_done=0;
    is_port_done=0;
    host = "awk.com";
    port = "4567";
}

in_agent_section == 1 {
    if ($0 ~ /^server[[:space:]]*=/) {
        print "server="host;
        is_host_done = 1;
        next;
    }
    else if ($0 ~ /^masterport[[:space:]]*=/) {
        print "masterport="port;
        is_port_done = 1;
        next;
    }
    else if ($0 ~ /^\[/) {
        in_agent_section = 0;
        if (! is_host_done) {
            print "server="host;
        }
        if (! is_port_done) {
            print "masterport="port;
        }
    }
}

/^\[agent\]/ {
    in_agent_section=1;
}

{ print; }

Usage:

$ awk -f ~/config.awk < /etc/puppet/puppet.conf > /tmp/puppet.conf
$ sudo mv /tmp/puppet.conf /etc/puppet/puppet.conf


