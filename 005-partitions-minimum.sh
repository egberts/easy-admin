#!/bin/bash
# File: 050-partitions-minimum.sh
# Title: Check for minimum set of partitions
# Description:
#   There are two parts to this check:
#
#     1) /etc/fstab and
#     2) /etc/mtab
#
#   We are doing both part, starting with /etc/fstab
#
# Reference:
#  CIS Security Debian 10 Benchmark, 1.0, 2020-02-13
#
# Prerequisites:
#  mount (mount)
#  gawk (awk)
#  grep (grep)
#  whereis (util-linux)
#  systemctl (systemd) - optional
#

# Check for systemd-wide
WHEREIS_SYSTEMCTL="$(whereis -b systemctl)"
if [ -z "$WHEREIS_SYSTEMCTL" ]; then
  echo "Not a systemd-controlled OS"
  # SYSTEMD_MODE=-1
else
  SYSTEMD_STATUS="$(systemctl is-system-running)"
  if [ "$SYSTEMD_STATUS" == 'offline' ] || \
     [ "$SYSTEMD_STATUS" == 'unknown' ]; then
#    SYSTEMD_MODE=0
    echo "This script cannot handle '$SYSTEMD_STATUS' state of systemd."
    echo "Manual investigation is required"
    echo "Aborted."
    exit 254
#  else
#    SYSTEMD_MODE=1
  fi
fi

ERR_MISSING_OPTIONS=0
ERR_MISSING_PARTITIONS=0

function check_option
{
# We are really catching any 'exec' after any 'noexec' styled avoidance
# fstab can do that; mtab, not so much (but do checks anyway)
  OPT_LIST="$(echo "${MTAB_MP_OPTIONS[$idx]}" | sed 's/[()]//g' | tr , "\n" | xargs)"
  opt_found=0
  for this_opt in $OPT_LIST; do
    if [ "$this_opt" == "$2" ]; then
      opt_found=1
    elif [ "$this_opt" == "$3" ]; then
      # cancel foundness
      opt_found=0
    fi
  done
  if [ "$opt_found" -eq 0 ]; then
    echo "  Missing '$2' in $REQ_MOUNT_DIRPATH"
    ((ERR_MISSING_OPTIONS+=1))
    BAD_OPTIONS+=(noexec)
  fi
}

# There are two different partition mount point tracking (fstab and systemd)
# Make a common match between the two

REQ_MOUNT_DIRPATHS=(/tmp /var/tmp /var /var/log /var/log/audit /home /dev/shm)
#REQ_MOUNT_OPTIONS=(
#"noexec nosuid nodev"
#"noexec nosuid nodev"
#""
#""
#""
#"nodev"
#"noexec nosuid nodev"
#)
REQ_MOUNT_PRESENT=(no no no no no no no)


# Always do /etc/fstab (it may be replaced later by systemd)
# capture entire uncommented fstab content
# FSTAB_MP_IDX_UNFOUND=()  # collect index to let systemd try on
echo "Reading file system (/etc/fstab) table file ..."
if [ -f /etc/fstab ]; then

  PARTITIONS_EXIST_ERROR=0
  FSTAB_LINES=("$(grep -E '^\s*(~#)*\s*[/a-zA-Z\=\_\-]+' /etc/fstab)")
#  FSTAB_MP_DEVICE=($(echo "$FSTAB_LINES" | awk '{print $1}'))
# shellcheck disable=SC2207
  FSTAB_MP_DIRPATH=($(echo "${FSTAB_LINES[*]}" | awk '{print $2}'))
#  FSTAB_MP_FSTYPE=($(echo "$FSTAB_LINES" | awk '{print $3}'))
#  FSTAB_MP_OPTS=($(echo "$FSTAB_LINES" | awk '{print $4}'))
#  FSTAB_5=($(echo "$FSTAB_LINES" | awk '{print $5}'))
#  FSTAB_6=($(echo "$FSTAB_LINES" | awk '{print $6}'))

  req_idx=0
  fstab_found_idx_a=()
  while [ $req_idx -lt ${#REQ_MOUNT_DIRPATHS[@]} ]; do

    MNT_POINT_FOUND_IN_FSTAB=0
    idx=0
    REQ_MOUNT_DIRPATH="${REQ_MOUNT_DIRPATHS[$req_idx]}"
    while [ $idx -lt ${#FSTAB_MP_DIRPATH[@]} ]; do
      if [ "${FSTAB_MP_DIRPATH[$idx]}" == "$REQ_MOUNT_DIRPATH" ]; then
        MNT_POINT_FOUND_IN_FSTAB=1
        case "$REQ_MOUNT_DIRPATH" in

        /dev/shm)
          ;;
        /home);;
        /var/log/audit);;
        /var/log);;
        /var);;
        /var/tmp);;
        /tmp);;
        *);;
        esac
      fi
      ((idx+=1))
    done
    if [ "$MNT_POINT_FOUND_IN_FSTAB" -eq 0 ]; then
      ((PARTITIONS_EXIST_ERROR+=1))
      # FSTAB_MP_IDX_UNFOUND[$fstab_found_idx_a]=$req_idx
      ((fstab_found_idx_a+=1))
    else
      REQ_MOUNT_PRESENT[$req_idx]="yes"
    fi
    ((req_idx+=1))
  done
fi

# Do /etc/mtab
echo "Reading mounted file systems attributes (mount) ..."
# shellcheck disable=SC2207
MTAB_MP_LINES=("$(mount | grep -E '^\s*(~#)*\s*[/a-zA-Z\=\_\-]+')")
# shellcheck disable=SC2207
# MTAB_MP_DEVICE=($(echo "${MTAB_MP_LINES[*]}" | awk '{print $1}'))
# shellcheck disable=SC2207
MTAB_MP_DIRPATH=($(echo "${MTAB_MP_LINES[*]}" | awk '{print $3}'))
# shellcheck disable=SC2207
MTAB_MP_FSTYPE=($(echo "${MTAB_MP_LINES[*]}" | awk '{print $5}'))
# shellcheck disable=SC2207
MTAB_MP_OPTIONS=($(echo "${MTAB_MP_LINES[*]}" | awk '{print $6}'))
# MTAB_MP_LABEL=($(echo "$MTAB_MP_LINES" | awk '{print $7}'))  # I see '[home]'
# echo "MTAB_MP_DIRPATH[@]: ${MTAB_MP_DIRPATH[@]}"
# echo "MTAB_MP_FSTYPE: ${MTAB_MP_FSTYPE[@]}"

# Two checks are made on mtab:
#  * required partition type check (iterates by required partitions)
#  * filesystem type check (iterates by each mtab entry)
#

#  Required partition type check (iterates by required partitions)
req_idx=0
# mtab_found_idx_a=()
while [ $req_idx -lt ${#REQ_MOUNT_DIRPATHS[@]} ]; do
  REQ_MOUNT_DIRPATH="${REQ_MOUNT_DIRPATHS[$req_idx]}"

  idx=0
  # MNT_POINT_FOUND_IN_MTAB=0
  while [ $idx -lt ${#MTAB_MP_DIRPATH[@]} ]; do

    # found the required mountpoints
    if [ "${MTAB_MP_DIRPATH[$idx]}" == "$REQ_MOUNT_DIRPATH" ]; then
      # MNT_POINT_FOUND_IN_MTAB=1
      OPT_LIST="$(echo "${MTAB_MP_OPTIONS[$idx]}" | sed 's/[()]//g' | tr , "\n" | xargs)"
      check_option "$OPT_LIST" "noexec" "exec"
      check_option "$OPT_LIST" "nosuid" "suid"
      check_option "$OPT_LIST" "nodev" "dev"

      # Iterate each actual options used
      REQ_MOUNT_PRESENT[$req_idx]="yes"
    fi
    ((idx+=1))
  done
  # Run check against filesystem
  ((req_idx+=1))
done

# Print out partitions that both fstab and mtab totally missed

req_idx=0
while [ $req_idx -lt ${#REQ_MOUNT_PRESENT[@]} ]; do
  if [ "${REQ_MOUNT_PRESENT[$req_idx]}" == "no" ]; then
    echo "Missing partition: ${REQ_MOUNT_DIRPATHS[$req_idx]}"
    ((ERR_MISSING_PARTITIONS+=1))
  fi
  ((req_idx+=1))
done

#  * filesystem type check (iterates by each mtab entry)
mtab_idx=0
# mtab_found_idx_a=()
while [ $mtab_idx -lt ${#MTAB_MP_DIRPATH[@]} ]; do
  # MOUNT_DIRPATH="${MTAB_MP_DIRPATH[$mtab_idx]}"
  MOUNT_FSTYPE="${MTAB_MP_FSTYPE[$mtab_idx]}"

  case $MOUNT_FSTYPE in
  swap) ;;
  ext4|ext3|ext2) ;;

  autofs)
    echo "ERROR: Need to remove 'autofs' from kernel module list"
    ;;
  esac
  ((mtab_idx+=1))
done

if [[ "$ERR_MISSING_PARTITIONS" -ge 1 ]] || \
   [[ "$ERR_MISSING_OPTIONS" -ge 1 ]]; then
  echo "Errors:"
  if [ "$ERR_MISSING_PARTITIONS" -ge 1 ]; then
    echo " Missing partitions:    $ERR_MISSING_PARTITIONS"
  fi
  if [ "$ERR_MISSING_OPTIONS" -ge 1 ]; then
    echo " Missing mount options: $ERR_MISSING_OPTIONS"
  fi
  echo "Not all partitions have been created in compliance to CIS benchmark."
  echo "FAIL"
  exit 251
else
  echo "PASS"
fi
echo "Done."
exit 0
