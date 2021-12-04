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
# Files impacted:
#  create - none
#  modify - none
#
# Prerequisites:
#  mount (mount)
#  gawk (awk)
#  grep (grep)
#  whereis (util-linux)
#  systemctl (systemd) - optional
#

# Check for systemd-wide
whereis_sysctl="$(whereis -b systemctl)"
if [ -z "$whereis_sysctl" ]; then
  echo "Not a systemd-controlled OS"
  # SYSTEMD_MODE=-1
else
  systemd_status="$(systemctl is-system-running)"
  if [ "$systemd_status" == 'offline' ] || \
     [ "$systemd_status" == 'unknown' ]; then
#    SYSTEMD_MODE=0
    echo "This script cannot handle '$systemd_status' state of systemd."
    echo "Manual investigation is required"
    echo "Aborted."
    exit 254
#  else
#    SYSTEMD_MODE=1
  fi
fi

err_missing_options=0
err_missing_partitions=0

function check_option
{
  # We are really catching any 'exec' after any 'noexec' styled avoidance
  # fstab can do that; mtab, not so much (but do checks anyway)
  opt_list="$(echo "${mtab_mp_options[$idx]}" | sed 's/[()]//g' | tr , "\n" | xargs)"
  opt_found=0
  for this_opt in $opt_list; do
    if [ "$this_opt" == "$2" ]; then
      opt_found=1
    elif [ "$this_opt" == "$3" ]; then
      # cancel foundness
      opt_found=0
    fi
  done
  if [ "$opt_found" -eq 0 ]; then
    echo "  Missing '$2' in $req_mount_dirpath"
    ((err_missing_options+=1))
    bad_options+=(noexec)
  fi
}


# There are two different partition mount point tracking (fstab and systemd)
# Make a common match between the two

# Define the required mount directories to check upon
req_mount_dirpaths=(/tmp /var/tmp /var /var/log /var/log/audit /home /dev/shm)

REQ_MOUNT_OPTIONS=(
"nosuid nodev"
"noexec nosuid nodev"
"nodev nosuid"
"nodev nosuid noexec"
"nodev nosuid noexec"
"nodev"
"noexec nosuid nodev"
)
req_mount_present=(no no no no no no no)

function check_options()
{
  dirpath="$1"
  options="$2"

  opt_idx=0
  while [ $opt_idx -lt ${#REQ_MOUNT_OPTIONS[@]} ]; do

    # if given dirpath equals required dirpath
    if [ "$dirpath" == "${req_mount_dirpaths[$opt_idx]}" ]; then
      for this_opt in ${REQ_MOUNT_OPTIONS[$opt_idx]}; do
        check_option "$options" "$this_opt" "${this_opt:2}"
      done
    fi
    ((opt_idx++))
  done
}

# Always do /etc/fstab (it may be replaced later by systemd)
# capture entire uncommented fstab content
# FSTAB_MP_IDX_UNFOUND=()  # collect index to let systemd try on
echo "Reading file system (/etc/fstab) table file ..."
if [ -f /etc/fstab ]; then

  partitions_exist_error=0

  # Read in all uncommented lines from /etc/fstab
  fstab_lines=("$(grep -E '^\s*(~#)*\s*[/a-zA-Z\=\_\-]+' /etc/fstab)")

  #  FSTAB_MP_DEVICE=($(echo "$fstab_lines" | awk '{print $1}'))

  # Extract mount directory from second column
  # shellcheck disable=SC2207
  fstab_mp_dirpath=($(echo "${fstab_lines[*]}" | awk '{print $2}'))

  #  FSTAB_MP_FSTYPE=($(echo "$fstab_lines" | awk '{print $3}'))
  #  FSTAB_MP_OPTS=($(echo "$fstab_lines" | awk '{print $4}'))
  #  FSTAB_5=($(echo "$fstab_lines" | awk '{print $5}'))
  #  FSTAB_6=($(echo "$fstab_lines" | awk '{print $6}'))

  req_idx=0
  fstab_found_idx_a=()

  # Iterate through all required mount points
  while [ $req_idx -lt ${#req_mount_dirpaths[@]} ]; do

    fstab_idx=0
    mnt_point_found_in_fstab=0

    # Obtain the mount directory path to this required entry
    req_mount_dirpath="${req_mount_dirpaths[$req_idx]}"

    # Compare required mount point against all actual mount points
    while [ $fstab_idx -lt ${#fstab_mp_dirpath[@]} ]; do

      # if required and actual mount points matches
      if [ "${fstab_mp_dirpath[$idx]}" == "$req_mount_dirpath" ]; then

        # Check further, depending on its mount type
        mnt_point_found_in_fstab=1
        case "$req_mount_dirpath" in

        /dev/shm)
          ;;
        /home);;
        /var/log/audit);;
        /var/log);;
        /var/tmp);;
        /var);;
        /tmp);;
        *);;
        esac
      fi
      ((fstab_idx+=1))
    done

    # if required mount point is not found in actual list
    if [ "$mnt_point_found_in_fstab" -eq 0 ]; then

      # document error
      ((partitions_exist_error+=1))
      # FSTAB_MP_IDX_UNFOUND[$fstab_found_idx_a]=$req_idx
      ((fstab_found_idx_a+=1))
    else
      req_mount_present[$req_idx]="yes"
    fi
    ((req_idx+=1))
  done
fi

# Do /etc/mtab

echo "Reading mounted file systems attributes (mount) ..."
# shellcheck disable=SC2207
mtab_mp_lines=("$(mount | grep -E '^\s*(~#)*\s*[/a-zA-Z\=\_\-]+')")
# shellcheck disable=SC2207
# MTAB_MP_DEVICE=($(echo "${mtab_mp_lines[*]}" | awk '{print $1}'))

# shellcheck disable=SC2207
mtab_mp_dirpath=($(echo "${mtab_mp_lines[*]}" | awk '{print $3}'))

# shellcheck disable=SC2207
mtab_mp_fstype=($(echo "${mtab_mp_lines[*]}" | awk '{print $5}'))

# shellcheck disable=SC2207
mtab_mp_options=($(echo "${mtab_mp_lines[*]}" | awk '{print $6}'))

# MTAB_MP_LABEL=($(echo "$mtab_mp_lines" | awk '{print $7}'))  # I see '[home]'
# echo "mtab_mp_dirpath[@]: ${mtab_mp_dirpath[@]}"
# echo "mtab_mp_fstype: ${mtab_mp_fstype[@]}"

# Two checks are made on mtab:
#  * required partition type check (iterates by required partitions)
#  * filesystem type check (iterates by each mtab entry)
#

#  Required partition type check (iterates by required partitions)
req_idx=0
# mtab_found_idx_a=()
while [ $req_idx -lt ${#req_mount_dirpaths[@]} ]; do
  req_mount_dirpath="${req_mount_dirpaths[$req_idx]}"

  idx=0
  # MNT_POINT_FOUND_IN_MTAB=0
  while [ $idx -lt ${#mtab_mp_dirpath[@]} ]; do

    # found the required mountpoints
    if [ "${mtab_mp_dirpath[$idx]}" == "$req_mount_dirpath" ]; then

      # MNT_POINT_FOUND_IN_MTAB=1

      # obtain current non-default settings of this mount entry
      opt_list="$(echo "${mtab_mp_options[$idx]}" | sed 's/[()]//g' | tr , "\n" | xargs)"

      check_options "${mtab_mp_dirpath[$idx]}" "$opt_list"
      # check_option "$opt_list" "noexec" "exec"
      # check_option "$opt_list" "nosuid" "suid"
      # check_option "$opt_list" "nodev" "dev"

      # Iterate each actual options used
      req_mount_present[$req_idx]="yes"
    fi
    ((idx+=1))
  done
  # Run check against filesystem
  ((req_idx+=1))
done

# Print out partitions that both fstab and mtab totally missed

req_idx=0
while [ $req_idx -lt ${#req_mount_present[@]} ]; do
  if [ "${req_mount_present[$req_idx]}" == "no" ]; then
    echo "Missing partition: ${req_mount_dirpaths[$req_idx]}"
    ((err_missing_partitions+=1))
  fi
  ((req_idx+=1))
done

#  * filesystem type check (iterates by each mtab entry)
mtab_idx=0
# mtab_found_idx_a=()
while [ $mtab_idx -lt ${#mtab_mp_dirpath[@]} ]; do
  # MOUNT_DIRPATH="${mtab_mp_dirpath[$mtab_idx]}"
  mount_fstype="${mtab_mp_fstype[$mtab_idx]}"

  case $mount_fstype in
  swap) ;;
  ext4|ext3|ext2) ;;

  autofs)
    echo "ERROR: Need to remove 'autofs' from kernel module list"
    echo "       as ${mtab_mp_dirpath[$mtab_idx]} directory is using autofs."
    ;;
  esac
  ((mtab_idx+=1))
done

if [[ "$err_missing_partitions" -ge 1 ]] || \
   [[ "$err_missing_options" -ge 1 ]]; then
  echo "Errors:"
  if [ "$err_missing_partitions" -ge 1 ]; then
    echo " Missing partitions:    $err_missing_partitions"
  fi
  if [ "$err_missing_options" -ge 1 ]; then
    echo " Missing mount options: $err_missing_options"
  fi
  echo "Not all partitions have been created in compliance to CIS benchmark."
  echo "FAIL"
  exit 251
else
  echo "PASS"
fi
echo "Done."
exit 0
