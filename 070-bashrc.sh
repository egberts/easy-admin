#!/bin/bash
# File: 070-bashrc.sh
# Title: Clean up bashrc
# Description:
#    Basic account setup with regard to bash shell handling
#
# Design:
#    For system-wide settings
#    Check if /etc/profile
#    Check if /etc/bashrc
#    Check if /etc/skel
#    For $HOME
#    Check if $HOME/.bashrc.d directory exist
#    chmod 0700 $HOME/.bashrc.d
#        mkdir $HOME/.bashrc.d/aliases
#        mkdir $HOME/.bashrc.d/completions
#        mkdir $HOME/.bashrc.d/plugins
#
#    Check for conflict between $HOME/.bashrc and $HOME/.bash_profile
#      which to use
#
#    If ".bashrc.d" does not exist in $HOME/.bashrc then
#        Add snippet to $HOME/.bashrc
#            for file in ~/.bashrc.d/*.bashrc; do
#                source "$file"
#            done
#        chmod a+x $HOME/.bashrc.d/*.bashrc

echo "Checking file permissions on various Bash script files"
echo ""

BASHRC_DROPIN_DIRNAME=".bashrc.d"
BASHRC_DROPIN_PATHNAME="$HOME"
BASHRC_DROPIN_DIRSPEC="${BASHRC_DROPIN_PATHNAME}/$BASHRC_DROPIN_DIRNAME"

echo "Checking for $BASHRC_DROPIN_DIRSPEC directory..."
if [ ! -d "$BASHRC_DROPIN_DIRSPEC" ]; then
  echo "Directory $BASHRC_DROPIN_DIRSPEC does not exist; creating..."
  mkdir "$BASHRC_DROPIN_DIRSPEC"
  chmod 0700 "$BASHRC_DROPIN_DIRSPEC"
fi
echo "Checking for $BASHRC_DROPIN_DIRSPEC subdirectories..."
for this_dir in aliases completions plugins; do
  THIS_DROPIN_DIRSPEC="$BASHRC_DROPIN_DIRSPEC/$this_dir"
  if [ ! -d "$THIS_DROPIN_DIRSPEC" ]; then
    echo "Directory $THIS_DROPIN_DIRSPEC does not exist; creating..."
    mkdir "$THIS_DROPIN_DIRSPEC"
    chmod 0700 "$THIS_DROPIN_DIRSPEC"
  fi
done

DOT_BASHRC_PATHNAME="$HOME"
DOT_BASHRC_FILENAME=".bashrc"
DOT_BASHRC_FILESPEC="$DOT_BASHRC_PATHNAME/$DOT_BASHRC_FILENAME"
echo "Checking for $DOT_BASHRC_FILESPEC script file..."
if [ -r "$DOT_BASHRC_FILESPEC" ]; then
  DOT_BASHRC_EXIST=1
else
  DOT_BASHRC_EXIST=0
fi

DOT_BASH_PROFILE_PATHNAME="$HOME"
DOT_BASH_PROFILE_FILENAME=".bash_profile"
DOT_BASH_PROFILE_FILESPEC="$DOT_BASH_PROFILE_PATHNAME/$DOT_BASH_PROFILE_FILENAME"
echo "Checking for $DOT_BASH_PROFILE_FILESPEC script file..."
if [ -r "$DOT_BASH_PROFILE_FILESPEC" ]; then
  DOT_BASH_PROFILE_EXIST=1
else
  DOT_BASH_PROFILE_EXIST=0
fi

# Should be OK by most latest distros to use both .bashrc and .bash_profile now
#if [ "$DOT_BASH_PROFILE_EXIST" -eq 1 ] &&
#   [ "$DOT_BASHRC_EXIST" -eq 1 ]; then
#  echo "Your login(1) is stable and uses $DOT_BASH_PROFILE_FILESPEC."
#  echo "It is confusing to be using both $DOT_BASH_PROFILE_FILESPEC and"
#  echo "   $DOT_BASHRC_FILESPEC together. Aborted"
#  exit 3
#fi

SKEL_PATHNAME="/etc/skel"
SKEL_DOT_BASHRC_FILENAME=".bashrc"
SKEL_DOT_BASHRC_FILESPEC="$SKEL_PATHNAME/$SKEL_DOT_BASHRC_FILENAME"
echo "Checking for $SKEL_DOT_BASHRC_FILESPEC skeleton bashrc file..."
if [ ! -d "$SKEL_PATHNAME" ]; then
  echo "No user account ($SKEL_PATHNAME) skeleton found; aborted."
  exit 1
fi
if [ ! -r "$SKEL_DOT_BASHRC_FILESPEC" ]; then
  echo "No predefined $SKEL_DOT_BASHRC_FILESPEC in new user account "
  echo "   skeleton directory found; aborted."
  exit 1
fi
echo ""

function create_dot_bashrc_header()
{
  cat << DOT_BASHRC_EOF | tee "$DOT_BASHRC_FILESPEC" >/dev/null 2>&1
#
# File: $(basename "$DOT_BASHRC_FILESPEC")
# Path: $(dir "$DOT_BASHRC_FILESPEC")
# Title: dot bashrc for \$HOME (~) directory
# Creator: $(basename "$0")
# Date: $(date)
#
DOT_BASHRC_EOF
}

function append_dot_bashrc_subdirs()
{
  FOUND_BASHRC_D_SUBDIRS="$(grep "aliases completions plugins" "$DOT_BASHRC_FILESPEC"|wc -l)"
  if [ "$FOUND_BASHRC_D_SUBDIRS" -eq 0 ]; then

    echo "Appending the .bashrc/<subdir> scripting to $DOT_BASHRC_FILESPEC ..."
    cat << DOT_BASHRC_EOF_2 | tee -a "$DOT_BASHRC_FILESPEC" >/dev/null 2>&1

#+++Appended by $0
# How to test ~/.bashrc.d file permission for strictness?
for this_dir in aliases completions plugins; do
  # sort the directory
  scripts="\$(ls -A \$HOME/${BASHRC_DROPIN_DIRNAME}/\$this_dir/*.bash 2>/dev/null)"
  for this_script in \$scripts; do
    # Only source those with exec-bit in its file permission setting
    if [ -x \$this_script ]; then
      source \$this_script
    fi
  done
done
#---Appended by $0
DOT_BASHRC_EOF_2
  else
    echo ".bashrc/<subdir> script segment found in $DOT_BASHRC_FILESPEC ..."
  fi
}

# Check if skeleton file has recently changed over user's bash file
DOT_BASHRC_TIMESTAMP="$(stat -c %Z "$DOT_BASHRC_FILESPEC")"
SKEL_DOT_BASHRC_TIMESTAMP="$(stat -c %Z "$SKEL_DOT_BASHRC_FILESPEC")"
if [ "$SKEL_DOT_BASHRC_TIMESTAMP" -gt "$DOT_BASHRC_TIMESTAMP" ]; then
  echo "change timestamps  "
  echo "$(stat -c %z "$SKEL_DOT_BASHRC_FILESPEC"): $SKEL_DOT_BASHRC_FILESPEC"
  echo "$(stat -c %z "$DOT_BASHRC_FILESPEC"): $DOT_BASHRC_FILESPEC"
  echo ""
  echo "Skeleton bashrc: $SKEL_DOT_BASHRC_FILESPEC"
  echo "Choices are:"
  echo "  (B)ackup .bashrc to .bashrc.backup; copy Skeleton+ to ~/.bashrc"
  echo "  (O)ver-write .bashrc with modified /etc/skel/.bashrc"
  echo "  (A)ppend drop-in scripting at end of your existing ~/.bashrc"
  echo "  (I)gnore the skeleton file; keep your existing ~/.bashrc"
  read -rp "Ignore, Backup, Overwrite, or Append to your ~/.bashrc file? (I/b/o/a): " -eiI
  REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  if [ -z "$REPLY" ] || [ "$REPLY" == 'b' ]; then
    mv -v -i "$DOT_BASHRC_FILESPEC" "$DOT_BASHRC_FILESPEC.backup"
    create_dot_bashrc_header
    cp -v -i "$SKEL_DOT_BASHRC_FILESPEC" "$DOT_BASHRC_FILESPEC"
    append_dot_bashrc_subdirs
  elif [ "$REPLY" == 'a' ]; then
    echo "Appending $DOT_BASHRC_FILESPEC..."
    append_dot_bashrc_subdirs
  elif [ "$REPLY" == 'o' ]; then
    "Overwriting $DOT_BASHRC_FILESPEC..."
    create_dot_bashrc_header
    cp -v -i "$SKEL_DOT_BASHRC_FILESPEC" "$DOT_BASHRC_FILESPEC"
    append_dot_bashrc_subdirs
  elif [ "$REPLY" == 'i' ]; then
    echo "Ignoring $DOT_BASHRC_FILESPEC..."
  else
    echo "Aborted."
    # exit 1
  fi
  echo ""
else
  append_dot_bashrc_subdirs
fi

# weird quirk - User having its group name the same as its user name
USER_NAME="$USER"
GROUP_NAME="$(grep ":${GROUPS[0]}:" /etc/group|awk '{print $1}')"
if [ "$USER_NAME" == "$GROUP_NAME" ]; then

  # Check if anyone else is using the user's own group
  DOT_BASHRC_GROUPNAME="$(stat -c %U "$DOT_BASHRC_FILESPEC")"
  echo ""
  echo "Current file: $DOT_BASHRC_FILESPEC"
  echo "Current file ownership:  $(stat -c %U:%G "$DOT_BASHRC_FILESPEC")"
  echo "Current file permission: $(stat -c %a "$DOT_BASHRC_FILESPEC")"
  echo "Current file permission: $(stat -c %A "$DOT_BASHRC_FILESPEC") (human-readable)"
  echo ""
  echo "Regarding your '${DOT_BASHRC_GROUPNAME}' group name, is anyone or any"
  echo "...cronjob/service/scripting using or needing to be using that "
  echo "...'$DOT_BASHRC_GROUPNAME' group name as well?"
  read -rp "Is anyone/anything else using your '${DOT_BASHRC_GROUPNAME}' group name? (N/y): " -eiN
  REPLY="$(echo "${REPLY:0:1}"|awk '{print tolower($1)}')"
  if [ -z "$REPLY" ] || [ "$REPLY" == "n" ]; then
    DOT_BASHRC_FPERM="0600"
    echo "Dropping $DOT_BASHRC_GROUPNAME privilege for $DOT_BASHRC_FILESPEC"
  else
    DOT_BASHRC_FPERM="0640"
    echo "Adding $DOT_BASHRC_GROUPNAME privilege for $DOT_BASHRC_FILESPEC"
  fi
  chmod "$DOT_BASHRC_FPERM" "$DOT_BASHRC_FILESPEC"
  echo ""
fi

echo "File permissions for bash scripts: OK"
echo "Done."
