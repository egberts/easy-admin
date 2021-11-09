#!/bin/bash
#
# File: 490-net-ssh.sh
# Title: Setup and harden SSH server
#
# Mozilla Security wants at least 3071 bits, we say 4096
# Minimum SSH moduli bits is now 2047.
SSH_MODULI_BITS=4096
SSH_MODULI_FILESPEC="${BUILDROOT}${ext_sysconfdir}/moduli"

source ./ssh-openssh-common
FILE_SETTINGS_FILESPEC="${BUILDROOT}/filemod-openssh-moduli.sh"

echo "Creating ${SSH_MODULI_BITS}-bits Diffie-Hellman moduli for DH/DSE hash..."
echo ""

SSH_MODULI_TMP_FILESPEC="/tmp/moduli-$SSH_MODULI_BITS"
SSH_MODULI_TMP_CANDIDATES_FILESPEC="${SSH_MODULI_TMP_FILESPEC}.candidates"
SSH_MODULI_TMP_SAFE_FILESPEC="${SSH_MODULI_TMP_FILESPEC}.safe"
SSH_MODULI_TMP_SAFE_FILTERED_FILESPEC="${SSH_MODULI_TMP_SAFE_FILESPEC}.filtered"

rm -f "${SSH_MODULI_TMP_FILESPEC}"
rm -f "${SSH_MODULI_TMP_CANDIDATES_FILESPEC}"
rm -f "${SSH_MODULI_TMP_SAFE_FILESPEC}"
rm -f "${SSH_MODULI_TMP_SAFE_FILTERED_FILESPEC}"

echo "Creating safe(r) temporary files ..."
touch "${SSH_MODULI_TMP_FILESPEC}"
chmod og-rwx "${SSH_MODULI_TMP_FILESPEC}"
touch "${SSH_MODULI_TMP_CANDIDATES_FILESPEC}"
chmod  og-rwx "${SSH_MODULI_TMP_CANDIDATES_FILESPEC}"
touch "${SSH_MODULI_TMP_SAFE_FILESPEC}"
chmod og-rwx "${SSH_MODULI_TMP_SAFE_FILESPEC}"
touch "${SSH_MODULI_TMP_SAFE_FILTERED_FILESPEC}"
chmod og-rwx "${SSH_MODULI_TMP_SAFE_FILTERED_FILESPEC}"

echo "Generating moduli of ${SSH_MODULI_BITS} bits..."
ssh-keygen -M generate \
    -O bits=${SSH_MODULI_BITS} \
    "${SSH_MODULI_TMP_CANDIDATES_FILESPEC}"

echo "Screening moduli of ${SSH_MODULI_BITS} bits..."
ssh-keygen -M screen \
        -f "${SSH_MODULI_TMP_CANDIDATES_FILESPEC}" \
        "${SSH_MODULI_TMP_SAFE_FILESPEC}"

awk '$5 > 3071' \
    "${SSH_MODULI_TMP_SAFE_FILESPEC}" \
    | tee "${SSH_MODULI_TMP_SAFE_FILTERED_FILESPEC}"

create_script_header "$SSH_MODULI_FILESPEC" "SSH Diffie-Hellman Pre-seeded Hash"
cat "${SSH_MODULI_TMP_SAFE_FILESPEC}" >> "${BUILDROOT}$SSH_MODULI_FILESPEC"

flex_chmod 640 "$SSH_MODULI_FILESPEC"
flex_chown root:ssh "$SSH_MODULI_FILESPEC"

echo "Cleaning up temporary files..."
rm "${SSH_MODULI_TMP_FILESPEC}"
rm "${SSH_MODULI_TMP_CANDIDATES_FILESPEC}"
rm "${SSH_MODULI_TMP_SAFE_FILESPEC}"
rm "${SSH_MODULI_TMP_SAFE_FILTERED_FILESPEC}"

echo "Done."
