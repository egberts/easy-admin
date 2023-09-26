#
# File: 020-repos-fedora-35.sh
# Title: Install basic packages into Fedora 35
#
# Privilege required: sudo root
# OS: Fedora 35
# Kernel: Linux
#
# Files impacted:
#  read   - /var/lib/dnf
#  create - (variables installed files)
#  modify - none
#  delete - none
#
# Environment Variables:
#   none
#
# Prerequisites:
#   dnf
#   sudo (sudo)
#
# References:
#   - https://www.dedoimedo.com/computers/centos-8-perfect-desktop.html
#
echo "Installing essential things for Fedora 35 ..."
echo

sudo dnf install strace
sudo dnf install rsyslog
echo

echo "Done."
