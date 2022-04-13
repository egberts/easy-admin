#!/bin/bash
# File: 015-pam-no-lockout-adm-group.sh
# Title: Prevent lockout due to /etc/nologin and disabled root account
# Description:
#
echo "Prevent Lockout Due to /etc/nologin & Disabled root Account"
echo

echo "Add the following in /etc/pam.d/login"
echo "just right before the 'auth requisite pam_nologin.so ...' line:"
echo

echo "    # TWEAK (prevents lockout due to /etc/nologin)"
echo "    # if you want to allow users in the adm group to log in"
echo "    # on a text console even if /etc/nologin exists"
echo "    # This would not work through remote term console (sshd)"
echo "    auth [default=ignore success=1] pam_succeed_if.so quiet user ingroup adm"

echo
echo "Then add user(s) that can ignore this /etc/nologin toward the 'adm' group:"
echo
echo "   usermod -a -G adm <privileged-username>"
echo
echo "Aborted."
