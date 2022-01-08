#!/bin/bash
# Flle: 522-cis-bind9-nologin.sh
# Title: Give the BIND User Account an Invalid Shell
#
# Prerequisites:
#  gawk (awk)
#  grep (grep)
#  passwd (passwd)
#  util-linux (whereis)
#  coreutils (basename, cat, dirname, id)

nologin_pattern="nologin"
NOLOGIN_BIN="$(whereis -b "$nologin_pattern" | awk '{print $2}')"
echo "$NOLOGIN_BIN"
if [ -z "$NOLOGIN_BIN" ]; then
  echo "Unable to find '$nologin_pattern' binary."
  echo "CIS-Bind9.11-2.2: FAIL"
  exit 5
fi
NOLOGIN_FILENAME="$(basename "$NOLOGIN_BIN")"
NOLOGIN_FILEPATH="$(dirname "$NOLOGIN_BIN")"

# Try the newest username first, 'bind'
user_name='bind'
BIND_USER_EXIST="$(id "$user_name" >/dev/null 2>&1)"
if [ $? -ne 0 ]; then
  # Try the original username, 'named'
  user_name='named'
  BIND_USER_EXIST="$(id "$user_name" >/dev/null 2>&1)"
fi
USER_SHELL="$(cat /etc/passwd|grep "$user_name" | awk -F: '{print $7}')"
SHELL_FILENAME="$(basename "$USER_SHELL")"
SHELL_FILEPATH="$(dirname "$USER_SHELL")"

if [ "$SHELL_FILENAME" != "$NOLOGIN_FILENAME" ] || \
   [ "$SHELL_FILEPATH" != "$NOLOGIN_FILEPATH" ]; then
  echo "Passwd '$user_name' entry needs $SHELL updating..."
  echo "chsh -s $NOLOGIN_BIN $user_name"
  chsh -s "$NOLOGIN_BIN" "$user_name"
  retsts=$?
  if [ $retsts -ne 0 ]; then
    echo "Unable to remediate shell '$USER_SHELL' of user '$user_name' into $NOLOGIN_BIN"
    echo "CIS-Bind9.11-2.2: FAIL"
    exit $retsts
  fi
fi
echo "CIS-Bind9.11-2.2: pass"
