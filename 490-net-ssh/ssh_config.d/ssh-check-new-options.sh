#!/bin/bash
# File: ssh-check-new-options.sh
# Title: Find any unused new SSH options
# Description:
#
#   capture 'ssh -G 8.8.8.8'
#   Read each options
#   find this uncommented option in current directory
#   if not found, ALERT
#
echo "Find any unused new SSH options"
echo
TMPFILE="$(mktemp /tmp/ssh_G_XXXX)"
conf_list="$(ls -1 *.conf)"
cat << SSH_G_EOF | tee "${TMPFILE}" > /dev/null
$(ssh -G 8.8.8.8)
SSH_G_EOF
while read -r line; do
  # echo "line: $line";
  keyword="$(echo "$line" | awk '{print $1}')"
  keyvalue="$(echo "$line" | awk '{print $2 $3 $4 $5 $6}')"
  echo -n "Searching ${keyword}: "
  not_found=1
  for this_file in $conf_list; do
    found="$(grep -E -i -c -- "^\s*${keyword}\s" "$this_file" )"
    if [ $found -ne 0 ]; then
      not_found=0
    fi
  done
  if [ "$not_found" -eq 1 ]; then
    echo "$keyword NOT found in *.conf"
  else
    echo
  fi
done < "${TMPFILE}"
echo

rm -- "${TMPFILE}"
echo "Done."
