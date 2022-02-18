#!/bin/bash
# File: 071-bashrc.d-editor.sh
# Title: Add default editor
# Design:
#   if ~/.bashrc.d subdirectory exist
#     if ~/.bashrc.d/plugins subdirectory exist
#       drop 'EDITOR.bash'
#       chmod a+x $HOME/.bashrc.d/*.bashrc/EDITOR.bash

TRY_EDITORS="nano vi vim emacs nvim ed nvi mcedit ne pico vile ex elvis"

BASHRC_DROPIN_DIRNAME=".bashrc.d"
BASHRC_DROPIN_PATHNAME="$HOME"
BASHRC_DROPIN_DIRSPEC="${BASHRC_DROPIN_PATHNAME}/$BASHRC_DROPIN_DIRNAME"

echo "Checking for a $BASHRC_DROPIN_DIRSPEC directory..."
if [ ! -d "$BASHRC_DROPIN_DIRSPEC" ]; then
  echo "Directory $BASHRC_DROPIN_DIRSPEC does not exist"
  exit 9
fi
THIS_DROPIN_DIRSPEC="$BASHRC_DROPIN_DIRSPEC/plugins"
echo "Checking for $THIS_DROPIN_DIRSPEC subdirectory..."
if [ ! -d "$THIS_DROPIN_DIRSPEC" ]; then
  echo "Directory $THIS_DROPIN_DIRSPEC does not exist; creating..."
  exit 9
fi

# Find installed editors
FOUND_EDITORS=
for this_editor in $TRY_EDITORS; do
  # Checking if Shorewall is installed

  # 'which' is too-Debian-specific
  # 'command -v' doesn't work if binary has restricted file permissions
  # 'whereis -b' is our cup-of-tea.
  editor_bin="$(whereis -b "$this_editor" | awk '{ print $2 }')"
  if [ -n "$editor_bin" ]; then
    FOUND_EDITORS+="$editor_bin "
  fi
done

echo ""
echo "Found the following editors."
echo "If your favorite editor is not on the list, install its package firstly."
echo "Then rerun $0 again."
echo ""
echo "Otherwise, go ahead and pick a number."

if [ -z "$FOUND_EDITORS" ]; then
  echo "No installed editors found."
  echo "  - Use ESC key to scan typed-in directory and autocomplete."
  read -e -r -p "Enter in filespec to your favorite editor binary: "
  if [ ! -x "$REPLY" ]; then
    echo "Binary $REPLY not found; aborted."
    exit 9
  fi
  DEFAULT_EDITOR="$REPLY"
else
  # Found editors, offer selection
  select this_editor in $FOUND_EDITORS; do
    DEFAULT_EDITOR="$this_editor"
    break;
  done
  echo "You have chosen the $DEFAULT_EDITOR editor."
fi
echo ""

# Select the default editor

EDITOR_BASHRC_DROPIN_PATHNAME="$HOME/.bashrc.d/plugins"
EDITOR_BASHRC_DROPIN_FILENAME="EDITOR.bash"
EDITOR_BASHRC_DROPIN_FILESPEC="$EDITOR_BASHRC_DROPIN_PATHNAME/$EDITOR_BASHRC_DROPIN_FILENAME"

echo "Writing for $EDITOR_BASHRC_DROPIN_FILESPEC script file..."
cat << BASHRC_DROPIN_EOF | tee "$EDITOR_BASHRC_DROPIN_FILESPEC" >/dev/null 2>&1
#
# File: $(basename "$EDITOR_BASHRC_DROPIN_FILESPEC")
# Path: $(dirname "$EDITOR_BASHRC_DROPIN_FILESPEC")
# Title: Default EDITOR for this user
# Creator: $(basename "$0")
# Date: $(date)
#

export EDITOR=${DEFAULT_EDITOR}
BASHRC_DROPIN_EOF

chmod 0750 "$EDITOR_BASHRC_DROPIN_FILESPEC"
echo "Created $EDITOR_BASHRC_DROPIN_FILESPEC script file."

echo "Done."
