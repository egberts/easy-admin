#!/bin/bash
# A test of extracting the location of the evoked script
# in order to find the accompanied yet associated other scripts
# for later reading or 'shell sourcing'.


# source_filename="distro-os.sh"
source_filename="source-me.sh"
MY_PATH=". \$HOME/bin /usr/bin /usr/local/bin"

function get_script_dirpath()
{
  # Get realpath to this script name
  real_path_script="$(realpath -e -- "$0")"
  retsts=$?
  # if an error occurred in realpath (ENOEXIST)
  if [ $retsts -ne 0 ]; then
    echo "File $0 does not exist."
    exit 9
  fi
  echo "Realpath: $real_path_script"
  SCRIPT_DIRPATH="$(dirname -- "$real_path_script")"
  echo "SCRIPT_DIRPATH: $SCRIPT_DIRPATH"
}

# Look for the shell scriptfile to source using $MY_PATH
function flex_source()
{
  this_filename=$1
  these_paths=$2
  if [ -z "$this_filename" ]; then
    echo "flex_source: parameter 1 empty"
    exit 2
  fi
  if [ -z "$these_paths" ]; then
    echo "flex_source: parameter 2 empty"
    exit 2
  fi
  source_filespec=
  for this_src_dirspec in $these_paths; do
    source_filespec="${this_src_dirspec}/$this_filename"
    if [ -r "$source_filespec" ]; then
      echo "Found $source_filespec in $this_src_dirspec directory."
      break
    fi
  done
  if [ ! -r "$source_filespec" ]; then
    echo "Error: File ${this_filename} not found in MYPATH=\"${these_paths}\"."
    exit 9
  fi
  echo "Sourcing: $source_filespec"
  # shellcheck disable=SC1090
  source "$source_filespec"
}

# Identify where this script is to add to $MY_PATH to use our other script files
get_script_dirpath

# Prepend this script's location into $MY_PATH
MY_PATH="$SCRIPT_DIRPATH $MY_PATH"

# Attempt to source  'os-distro.sh' from $MY_PATH
flex_source "$source_filename" "$MY_PATH"
echo "I sourced something, didn't I?"
