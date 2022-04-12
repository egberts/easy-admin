#!/bin/bash
#
# File: 490-net-ssh.sh
# Title: Setup and harden SSH server
#
# Examples:
#   ./495-net-ssh-moduli.sh
#   SSH_MODULI_BITS=512 ./495-net-ssh-moduli.sh  # one hour'ish
#   SSH_MODULI_BITS=8192 ./495-net-ssh-moduli.sh  # takes about 2 days
#
# Environment settings:
#   SSH_MODULI_BITS - 512 to 8192
#
echo "OpenSSH Moduli File Creator"
echo

# SSH_USE_STRONG_RNG - 14 to infinity, default 14

source ./maintainer-ssh-openssh.sh

case $ID in
  debian)
    if [ "$VERSION_ID" -lt 8 ]; then
      ssh_keygen_version=0
    else
      ssh_keygen_version=1
    fi
    ;;
  redhat)
    if [ "$VERSION_ID" -le 8 ]; then
      ssh_keygen_version=0
    else
      ssh_keygen_version=1
    fi
    ;;
  fedora)
    if [ "$VERSION_ID" -le 29 ]; then
      ssh_keygen_version=0
    else
      ssh_keygen_version=1
    fi
    ;;
  centos)
    if [ "$VERSION_ID" -le 8 ]; then
      ssh_keygen_version=0
    else
      ssh_keygen_version=1
    fi
    ;;
  arch)
    ssh_keygen_version=1
    ;;
esac

ssh_moduli_bits="${SSH_MODULI_BITS:-4096}"

ssh_moduli_filename="moduli"
ssh_moduli_filespec="${OPENSSH_CONFIG_DIRSPEC}/$ssh_moduli_filename"

temp_moduli_filespec="/tmp/${ssh_moduli_filename}-${ssh_moduli_bits}"
temp_moduli_candidates_filespec="${temp_moduli_filespec}.candidates"
temp_moduli_safe_filespec="${temp_moduli_filespec}.safe"

touch "$temp_moduli_filespec"
chmod og-rwx "$temp_moduli_filespec"

touch "$temp_moduli_candidates_filespec"
chmod og-rwx "$temp_moduli_candidates_filespec"

touch "$temp_moduli_safe_filespec"
chmod og-rwx "$temp_moduli_safe_filespec"

echo "Generating ${ssh_moduli_bits}-bit moduli candidates (long time)..."
echo "... in ${temp_moduli_candidates_filespec} ..."
if [ "$ssh_keygen_version" -eq 0 ]; then
  ssh-keygen -G "$temp_moduli_candidates_filespec" \
      -b "$ssh_moduli_bits"
  ssh-keygen -T "$temp_moduli_safe_filespec" \
      -f "$temp_moduli_candidates_filespec" 
else
  ssh-keygen -M generate \
      -O bits="${ssh_moduli_bits}" \
      "${temp_moduli_safe_filespec}"

  echo "Screening moduli of ${ssh_moduli_bits} bits..."
  ssh-keygen -M screen \
          -f "${temp_moduli_safe_filespec}" \
          "${temp_moduli_safe_filespec}"
fi

cp "${temp_moduli_safe_filespec}" "${BUILDROOT}$ssh_moduli_filespec"
echo "Completed the Moduli Generation."

flex_chmod 640 "$ssh_moduli_filespec"
flex_chown root:ssh "$ssh_moduli_filespec"

echo "Removing temporary files ..."
rm "$temp_moduli_candidates_filespec"
rm "$temp_moduli_safe_filespec"
rm "$temp_moduli_filespec"
echo ""

echo "Done."

