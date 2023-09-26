#
# File: 021-repos-centos-nice-things.sh
# Title: Install nice thing related to CentOS
#
# Privilege required: sudo root
# OS: CentOS
# Kernel: Linux
#
# Files impacted:
#  read   - /var/lib/dnf
#  create - (various installed files)
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
echo "Installing nice things on Debian"
echo

sudo dnf install kde-settings
sudo dnf install kde-settings-plasma
sudo dnf install qt-settings
sudo dnf install kde-gtk-config

sudo dnf install gimp libreoffice-writer steam

sudo dnf install vlc

sudo dnf install "downloaded chrome or skype rpm"
echo

echo "Done."
