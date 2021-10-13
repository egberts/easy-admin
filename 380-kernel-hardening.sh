#!/bin/bash
# File: 380-kernel-hardening
# Title: Special cases of kernel hardening
# References:
#  * https://forums.whonix.org/t/should-all-kernel-patches-for-cpu-bugs-be-unconditionally-enabled-vs-performance-vs-applicability/7647

# Tighen up access to /boot mount point
if [ -r /boot ]; then
  sudo chmod o-rwx /boot/*
fi
sudo chmod o-rwx /boot

# Add kernel line settings

DEFAULT_DIR="/tmp/etc/default"
DEFAULT_GRUB_D_DIR="$DEFAULT_DIR/grub.d"

mkdir -p "$DEFAULT_GRUB_D_DIR"
### chmod o-rwx "$DEFAULT_GRUB_D_DIR"

# CPU mitigation for SPECTRE
FILENAME="40_cpu_mitigation.cfg"
FILEPATH="$DEFAULT_GRUB_D_DIR"
FILESPEC="$FILEPATH/$FILENAME"
cat << GRUB_CFG_EOF | sudo tee $FILESPEC 1>/dev/null
#
# File: ${FILENAME}
# Path: ${FILEPATH}
# Title: CPU mitigation for SPECTRE variant 2
# Creator: $(basename "$0")
# Date: $(date)
#
## Copyright (C) 2019 - 2021 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

##
## https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/spectre.html
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX spectre_v2=on"

## Disable Speculative Store Bypass.
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX spec_store_bypass_disable=on"

## Disable TSX, enable all mitigations for the TSX Async Abort
## vulnerability and disable SMT.
##
## https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/tsx_async_abort.html
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX tsx=off tsx_async_abort=full,nosmt"

## Enable all mitigations for the MDS vulnerability and disable
## SMT.
##
## https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/mds.html
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX mds=full,nosmt"

## Enable all mitigations for the L1TF vulnerability and disable SMT
## and L1D flush runtime control.
##
## https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/l1tf.html
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX l1tf=full,force"

## Force disable SMT as it has caused numerous CPU vulnerabilities.
##
## https://forums.whonix.org/t/should-all-kernel-patches-for-cpu-bugs-be-unconditionally-enabled-vs-performance-vs-applicability/7647/17
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX nosmt=force"

## Mark all huge pages in the EPT as non-executable to mitigate iTLB multihit.
##
## https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/multihit.html#mitigation-control-on-the-kernel-command-line-and-kvm-module-parameter
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX kvm.nx_huge_pages=force"
GRUB_CFG_EOF

FILENAME="40_distrust_cpu.cfg"
FILEPATH="$DEFAULT_GRUB_D_DIR"
FILESPEC="$FILEPATH/$FILENAME"
cat << GRUB_CFG_EOF | sudo tee $FILESPEC 1>/dev/null
#
# File: $FILENAME
# Path: $FILEPATH
# Title: Distrust CPU for initial entropy at boot-time
# Creator: $(basename "$0")
# Date: $(date)
#

## Copyright (C) 2019 - 2021 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## Distrusts the CPU for initial entropy at boot as it is not possible to
## audit, may contain weaknesses or a backdoor.
##
## https://en.wikipedia.org/wiki/RDRAND#Reception
## https://twitter.com/pid_eins/status/1149649806056280069
## https://archive.nytimes.com/www.nytimes.com/interactive/2013/09/05/us/documents-reveal-nsa-campaign-against-encryption.html
## https://forums.whonix.org/t/entropy-config-random-trust-cpu-yes-or-no-rng-core-default-quality/8566
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX random.trust_cpu=off"

GRUB_CFG_EOF

FILENAME="40_enable_iommu.cfg"
FILEPATH="$DEFAULT_GRUB_D_DIR"
FILESPEC="$FILEPATH/$FILENAME"
cat << GRUB_CFG_EOF | sudo tee $FILESPEC 1>/dev/null
#
# File: ${FILENAME}
# Path: ${FILEPATH}
# Title: Force-enable IOMMU capability at boot time
# Creator: $(basename "$0")
# Date: $(date)
#

## Copyright (C) 2019 - 2021 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## Enables IOMMU to prevent DMA attacks.
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX intel_iommu=on amd_iommu=on"

## Disable the busmaster bit on all PCI bridges during very
## early boot to avoid holes in IOMMU.
##
## https://mjg59.dreamwidth.org/54433.html
## https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=4444f8541dad16fefd9b8807ad1451e806ef1d94
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX efi=disable_early_pci_dma"
GRUB_CFG_EOF


FILENAME="40_kernel_hardening.cfg"
FILEPATH="$DEFAULT_GRUB_D_DIR"
FILESPEC="$FILEPATH/$FILENAME"
cat << GRUB_CFG_EOF | sudo tee $FILESPEC 1>/dev/null
#
# File: ${FILENAME}
# Path: ${FILEPATH}
# Title: Kernel hardening at boot time
# Creator: $(basename "$0")
# Date: $(date)
#

## Copyright (C) 2019 - 2021 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

kpkg="linux-image-\$(dpkg --print-architecture)" || true
kver="\$(dpkg-query --show --showformat='\${Version}' "\$kpkg")" 2>/dev/null || true
#echo "## kver: \$kver"

## Disables the merging of slabs of similar sizes.
## Sometimes a slab can be used in a vulnerable way which an attacker can exploit.
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX slab_nomerge"

if dpkg --compare-versions "\$kver" ge "5.3"; then
  ## Enables sanity checks (F) and redzoning (Z).
  GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX slub_debug=FZ"

  #echo "## \$kver grater or equal 5.3: yes"
  ## Zero memory at allocation and free time.
  GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX init_on_alloc=1 init_on_free=1"
else
  #echo "## \$kver grater or equal 5.3: no"
  ## SLUB poisoning and page poisoning is used if the kernel
  ## does not yet support init_on_{,alloc,free}.
  GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX slub_debug=FZP"

  if command -v "qubesdb-read" >/dev/null 2>&1 ; then
     ## https://github.com/QubesOS/qubes-issues/issues/5212#issuecomment-533873012
     true "skip adding page_poison=1 in Qubes"
  else
     GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX page_poison=1"
  fi
fi

## Makes the kernel panic on uncorrectable errors in ECC memory that an attacker could exploit.
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX mce=0"

## Enables Kernel Page Table Isolation which mitigates Meltdown and improves KASLR.
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX pti=on"

## Vsyscalls are obsolete, are at fixed addresses and are a target for ROP.
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX vsyscall=none"

## Enables page allocator freelist randomization.
if dpkg --compare-versions "\${kver}" ge "5.2"; then
  GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX page_alloc.shuffle=1"
fi

## Enables kernel lockdown.
##
## Disabled for now as it enforces module signature verification which breaks
## too many things.
## https://forums.whonix.org/t/enforce-kernel-module-software-signature-verification-module-signing-disallow-kernel-module-loading-by-default/7880
##
#if dpkg --compare-versions "\${kver}" ge "5.4"; then
#  GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX lockdown=confidentiality"
#fi

## Gather more entropy during boot.
##
## Requires linux-hardened kernel patch.
## https://github.com/anthraxx/linux-hardened
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX extra_latent_entropy"

## Prevent kernel info leaks in console during boot.
## https://phabricator.whonix.org/T950
## str_replace is provided by package helper-scripts.
## Remove "quiet" from GRUB_CMDLINE_LINUX_DEFAULT because "quiet" must be first.
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX quiet loglevel=0"
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX loglevel=0"

## Restrict access to debugfs since it can contain a lot of sensitive information.
## https://lkml.org/lkml/2020/7/16/122
## https://github.com/torvalds/linux/blob/fb1201aececc59990b75ef59fca93ae4aa1e1444/Documentation/admin-guide/kernel-parameters.txt#L835-L848
GRUB_CMDLINE_LINUX="\$GRUB_CMDLINE_LINUX debugfs=off"
GRUB_CFG_EOF

echo "Done."
