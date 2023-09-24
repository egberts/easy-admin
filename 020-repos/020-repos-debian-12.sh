#!/bin/bash
#
# OS: Debian 12
# Kernel: 6.1.0
#
# Everything except the Linux kernel

echo "Kernel 6.1.0 requires some more packages"


sudo apt -y install dh-exec             # debian bug in 'autoremove'
sudo apt -y install dh-python
sudo apt -y install libssl-dev
sudo apt -y install rsync
sudo apt -y install quilt
sudo apt -y install sphinx-common
sudo apt -y install sphinx-rtd-theme-common

sudo apt -y install python3-sphinx-rtd-theme

# supply missing 'fc-list' using fontconfig package
sudo apt -y install fontconfig

sudo apt -y install libcpupower1 libcpupower-dev linux-cpupower

# Kernel utilities dependencies
sudo apt -y install kernel-wedge
sudo apt -y install lz4 
sudo apt -y install dwarves 
sudo apt -y install libcap-dev 
sudo apt -y install libpci-dev 
sudo apt -y install libglib2.0-dev 
sudo apt -y install libudev-dev 
sudo apt -y install libwrap0-dev 
sudo apt -y install asciidoctor 
sudo apt -y install gcc-multilib 
sudo apt -y install libaudit-dev 
sudo apt -y install libbabeltrace-dev 
sudo apt -y install libbabeltrace-dev 
sudo apt -y install libbabeltrace-ctf-dev 
sudo apt -y install libdw-dev 
sudo apt -y install libiberty-dev 
sudo apt -y install libnewt-dev 
sudo apt -y install libnuma-dev 
sudo apt -y install libperl-dev 
sudo apt -y install libunwind-dev 
sudo apt -y install libopencsd-dev 
sudo apt -y install python3-dev 
sudo apt -y install graphviz 
sudo apt -y install texlive-latex-base 
sudo apt -y install texlive-latex-extra 
sudo apt -y install dvipng

# server-specific
sudo apt -y install chrony
