#!/bin/bash
# File: 155-password-no-visual-echo.sh
# Title: No visual echo when typing in sudo password
#
#  /etc/sudoers was introduced in 1983 (BSD), so it's forever.
#  @includedir keyword introduced in sudo v1.7.0 (2009)

echo "Enforce no visual echo when typing in sudo password"
echo

SUDOERS_CONFIG_FILESPEC="/etc/sudoers"
SUDOERS_D_CONFIG_DIRSPEC="/etc/sudoers.d"

my_sudo_prechecker() {
    local sudo_msg
    sudo_msg=$(sudo -Nnv 2>&1)
    case "$?" in
        0)  # No password needed
            return 0
            ;;
        1)  # Password is required
            case "$sudo_msg" in
                *'password is required'*)
                    echo "Password required, prepare accordingly..."
                    # Add your specific preparation code here
                    return 1
                    ;;
                *)
                    echo "Unexpected sudo output: $sudo_msg"
                    return 2
                    ;;
            esac
            ;;
        *)
            echo "Failed to check sudo status."
            return 3
            ;;
    esac
}

# Usage example
my_sudo_prechecker
RETSTS=$?
if [ $RETSTS -ne 0 ]; then
    echo "Password is required or an error occurred during sudo check; aborted"
    exit 11
fi


# no need to do version checking for file /etc/sudoers was
# always there since version 0.34

# '@includedir' keyword was introduced in v1.7.0 (2009)
# so check for 'sudo --version', first line, 3rd argument

SUDO_VERSION="$(sudo --version | head -n1 | awk '{print $3}')"
if [ -z "$SUDO_VERSION" ]; then
  echo "No versioning support in sudo; aborted."
  exit 1
fi
echo "Sudo version: $SUDO_VERSION"

if [[ "$SUDO_VERSION" > "1.6.0" ]]; then
  if sudo -n true; then
    echo "sudo -n true works"
  else
    echo "sudo -n true does not works"
  fi
fi

TARGET_FILESPEC="$SUDOERS_CONFIG_FILESPEC"
if [[ "$SUDO_VERSION" > "1.7.0" ]]; then
  echo "This version supports '@includedir' keyword; check for it"
  (( IGNORE_INCLUDE=0 ))
  # check for '@includedir' declaration in /etc/sudoers (do not nest any deeper)
  INCLUDE_DIR="$(sudo grep -P '^\s*\@includedir' $TARGET_FILESPEC | awk '{ print $2 }')"
  # if commented out or never defined, it is a standalone /etc/sudoers
  if [ -z "$INCLUDE_DIR" ]; then
    echo "No '@includedir' found in $TARGET_FILESPEC"
    (( IGNORE_INCLUDE=1 ))
  # Warn and exit if not /etc/sudoers.d/ subdirectory (safety)
  elif [ "$INCLUDE_DIR" != "$SUDOERS_D_CONFIG_DIRSPEC" ]; then
    echo "For safety reason, we won't touch non-standard $INCLUDE_DIR; aborted"
    # exit prematurely due to non-standard @includedir
    exit 11
  else
    TARGET_FILESPEC="$SUDOERS_D_CONFIG_DIRSPEC"
  fi
  if [ $IGNORE_INCLUDE -eq 0 ]; then
    echo "@includedir is $INCLUDE_DIR"
    # Test if /etc/sudoers.d subdirectory exist
    if [ ! -d $SUDOERS_D_CONFIG_DIRSPEC ]; then
      echo "File /etc/sudoers.d is not a directory; aborted."
      exit 9
    fi
    # test if /etc/sudoers.d is readable
    # this assumes that '/etc' is globally readable
    if [ ! -r /etc/sudoers.d ]; then
      echo "File /etc/sudoers.d is not readable; aborted."
      exit 9
    fi
  fi
else
  echo "This version does not use '@includedir' keyword; ignore that."
  (( IGNORE_INCLUDE=1 ))
fi

# Target directory location verified, but not necessarily needed ... yet

# Check for any 'Defaults [!]pwfeedback', one must be found
ANY_PWFEEDBACK_SEEN="$(grep -E '^[[:space:]]*Defaults[^#]*\bpwfeedback\b' ${SUDOERS_CONFIG_FILESPEC})"
if [ $IGNORE_INCLUDE -eq 0 ]; then
  ALL_PWFEEDBACK_SEEN_SUBDIR="$(grep -E '^[[:space:]]*Defaults[^#]*\bpwfeedback\b' ${SUDOERS_D_CONFIG_DIRSPEC}/* | awk -F: '{ print $2 }' | awk '{ print $2 }' | xargs)"
  FILESPEC_FOUND_IN_SUBDIR="$(sudo grep -E '^[[:space:]]*Defaults[^#]*\bpwfeedback\b' ${SUDOERS_D_CONFIG_DIRSPEC}/* | awk -F: '{ print $1 }' | xargs)"
else
  FILESPEC_FOUND_IN_SUBDIR=""
  ALL_PWFEEDBACK_SEEN_SUBDIR=""
fi

SINGLE_PATTERN_FOUND=0
# If pwfeedback are not found anywhere, insert it
if [ -z "$ANY_PWFEEDBACK_SEEN" ] && [ -z "$ALL_PWFEEDBACK_SEEN_SUBDIR" ]; then
  echo "'Defaults [!]pwfeedback' Not found anywhere"
  # Decide where to insert this directive
  # Do we have '@includedir' declared?
  if [ $IGNORE_INCLUDE -eq 0 ]; then
    TARGET_FILESPEC="/etc/sudoers.d/password-no-visual-echo"
  else
    TARGET_FILESPEC="/etc/sudoers"
  fi
  echo "Targeting $TARGET_FILESPEC"
  SINGLE_PATTERN_FOUND=0

# if pwfeedback are found in multiple places, abort
elif [ -n "$ANY_PWFEEDBACK_SEEN" ] && [ -n "$ALL_PWFEEDBACK_SEEN_SUBDIR" ]; then
  echo "Saw pwfeedback in /etc/sudoers: $ANY_PWFEEDBACK_SEEN"
  echo "Saw pwfeedback in /etc/sudoers.d/*: $FILESPEC_FOUND_IN_SUBDIR"
  echo "2 ERROR: 'Defaults [!]pwfeedback' found in both /etc/sudoer and /etc/sudoers.d/*'; clean it up; aborted."
  exit 11

# if pwfeedback is found just in /etc/sudoers config file
elif [ -n "$ANY_PWFEEDBACK_SEEN" ]; then
  TARGET_FILESPEC="/etc/sudoers"
  echo "'Defaults [!]pwfeedback' found in $TARGET_FILESPEC"
  if [ "$ALL_PWFEEDBACK_SEEN_SUBDIR" == "Defaults !pwfeedback" ]; then
    echo "No change in $TARGET_FILESPEC needed."
    exit 1
  fi
  SINGLE_PATTERN_FOUND=1

# if pwfeedback is found just in /etc/sudoers.d/ subdirectory
elif [ -n "$ALL_PWFEEDBACK_SEEN_SUBDIR" ]; then
  echo "File(s) are: $FILESPEC_FOUND_IN_SUBDIR  in /etc/sudoers.d/*"
  TARGET_FILESPEC="/etc/sudoers.d/password-no-visual-echo"
  echo "'${ALL_PWFEEDBACK_SEEN_SUBDIR}' found in $TARGET_FILESPEC"
  INCLUDE_FILENAMES_COUNT=$(echo "$FILESPEC_FOUND_IN_SUBDIR" | wc -w)
  echo "Counted $INCLUDE_FILENAMES_COUNT files in /etc/sudoers.d/*"
  if [ "$INCLUDE_FILENAMES_COUNT" -gt 1 ]; then
    echo "Too many 'Defaults [!]pwfeedback' in $INCLUDE_DIR"
    exit 1
  elif [ "$INCLUDE_FILENAMES_COUNT" -eq 1 ]; then
    # We assume 1 file have 'Default [!]pwfeedback'
    if [ "$ALL_PWFEEDBACK_SEEN_SUBDIR" == "!pwfeedback" ]; then
      echo "No change in $ALL_PWFEEDBACK_SEEN_SUBDIR needed."
      exit 1
    fi
    SINGLE_PATTERN_FOUND=1
    # Insertion is needed
  elif [ "$INCLUDE_FILENAMES_COUNT" -eq 0 ]; then
    # We assume no file have 'Default [!]pwfeedback'
    echo "No 'Defaults [!]pwfeedback' found in $INCLUDE_DIR"
    # Creation needed
    SINGLE_PATTERN_FOUND=0
  else
    echo "Funky 'wc -w' command; aborted"
    exit 2
  fi
fi
echo "AHHH BORT!"
echo "Working on $TARGET_FILESPEC"

# change/update/create boundary
# Are we creating a new file or updating an existing file?
EDIT_ACTION="unknown"
if [ -f "$TARGET_FILESPEC" ]; then
  if [ "$SINGLE_PATTERN_FOUND" -eq 0 ]; then
    EDIT_ACTION="append"
  else
    EDIT_ACTION="update"
  fi
else
  EDIT_ACTION="create"
fi

if [ "$EDIT_ACTION" == "create" ]; then
  echo "Creating $TARGET_FILESPEC ..."
  echo "Defaults pwfeedback" | sudo tee $TARGET_FILESPEC > /dev/null
elif [ "$EDIT_ACTION" == "append" ]; then
  echo "Appending $TARGET_FILESPEC ..."
  echo "Defaults pwfeedback" | sudo tee $TARGET_FILESPEC > /dev/null
elif [ "$EDIT_ACTION" == "update" ]; then
  echo "Determine if the correct logic is used"
  # NEGATIVE_PWFEEDBACK="$(sudo grep -Ei '^\s*Defaults\s+([^#]+,\s*)?pwfeedback(,\s+\S+\s*)*(\s+#.*)?$' $TARGET_FILESPEC)"
  NEGATIVE_PWFEEDBACK="$(sudo grep -E '^[[:space:]]*Defaults[[:space:]]+([^#]*,)?pwfeedback(,[^#]*)?' "$TARGET_FILESPEC")"
  if [ -z "$NEGATIVE_PWFEEDBACK" ]; then
    echo "Correct logic used; nothing needs changing"
    exit 1
  fi
  echo "Updating $TARGET_FILESPEC ..."
  # use '~', sudo ignores those (don't use '.bak' filetype)
  sudo sed -i~ -E '/^[[:space:]]*Defaults[[:space:]]/ s/(^|[[:space:]],?)pwfeedback([[:space:]]|,|$)/\1!pwfeedback\2/g' $TARGET_FILESPEC
else
  echo "Unknown edit action '$EDIT_ACTION'; aborted"
  exit 3
fi

echo "CHECKPOINT 1"
# Enforce permissions
owner=$(stat -c "%U" "$TARGET_FILESPEC")
group=$(stat -c "%G" "$TARGET_FILESPEC")
perm=$(stat -c "%a" "$TARGET_FILESPEC")

if [[ "$owner" != "root" || "$group" != "root" || "$perm" != "640" ]]; then
  echo "$TARGET_FILESPEC may have incorrect permissions or ownership:"
  echo "Owner: $owner, Group: $group, Permissions: $perm"

  # Fix ownership
  sudo chown root:root "$TARGET_FILESPEC"

  # Fix permissions
  sudo chmod 0640 "$TARGET_FILESPEC"

  owner=$(stat -c "%U" "$TARGET_FILESPEC")
  group=$(stat -c "%G" "$TARGET_FILESPEC")
  perm=$(stat -c "%a" "$TARGET_FILESPEC")
fi

echo "Owner: $owner, Group: $group, Permissions: $perm"
echo "$TARGET_FILESPEC has correct permissions and ownership."
echo "Done."
exit 0
