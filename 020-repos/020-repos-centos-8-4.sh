#
# File: 020-repos-centos-8-4.sh
# Title: Install everything related to CentOS
#
# Privilege required: sudo root
# OS: CentOS
# Kernel: Linux
#
# Files impacted:
#  read   - /etc/alternatives/python
#  create - (various installed files)
#  modify - none
#  delete - none
#
# Environment Variables:
#   none
#
# Prerequisites:
#   coreutils (ln, rm)
#   dnf
#   sudo (sudo)
#
# References:
#   - https://www.dedoimedo.com/computers/centos-8-perfect-desktop.html
#
echo "Installing essential things for CentOS 8.4"
echo
if [ 0 -ne 0 ]; then
  sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

  sudo dnf install https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm

  sudo dnf install https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm

  #
  sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
  sudo dnf install gh
fi

# Replace python symlink with python3 in /etc/alternatives
if [ -f /etc/alternatives/python ]; then
  REAL_PYTHON="$(readlink /etc/alternatives/python)"
  if [[ "$REAL_PYTHON" == *no-python* ]]; then
    sudo rm /etc/alternatives/python
    sudo ln -s /etc/alternatives/python3 /etc/alternatives/python
  else
    echo "Unable to revert python3 to python in /etc/alternatives; skipping"
  fi
else
  sudo ln -s /etc/alternatives/python3 /etc/alternatives/python
fi
if [ -f /usr/bin/python ]; then
  REAL_PYTHON="$(readlink /etc/alternatives/python)"
  if [[ "REAL_PYTHON" == *no-python* ]]; then
    echo "no-python found"
    sudo rm /usr/bin/python
    sudo ln -s /etc/alternatives/python /usr/bin/python
  else
    echo "Unable to revert python3 to python in /usr/bin; skipping"
    echo "Aborted."
    exit 11
  fi
else
  sudo ln -s /etc/alternatives/python /usr/bin/python
fi
echo

echo "Done."
