#!/bin/bash
# File: basename_noline.sh
# Title: exercise 'basename' in a POSIX manner
#
# SHELLs Confirmed:
#   yes - bash 5.1.4/Linux/Debian
#   ??? - zsh/MacOS/Catalina

# POSIX basename/dirname do not have --zero/-0, yet
# we must eat the leading '\n' somehow

# syntax: basename_noline <filespec>
# works in all corner cases of filespec
# having a whitespace suffix or prefix,
# or having '.', '..', or '/' in any
# component of its filespec.

function basename_noline()
{
  if [ -n "$1" ]; then
    # pass '--' to terminate option parsing and start taking in an argument
    # POSIX output always has an '\n' so append an 'x' for later takeout
    b="$(basename -- "$1"; echo x)"
    # strip of last two character of '\n' and 'x'
    b="${b%??}"
    # output but without the '\n' character
    echo -n "$b"
  else
    echo "basename: missing operand."
    exit 1
  fi
}


if [ -n "$UNITTEST" ]; then
  echo "Unittest: real_basename_noline(): started"

  function basename_match()
  {
    # this_dir=$(realpath -m ${1}; echo x) ; this_dir=${this_dir%??}
    this_dir="$(realpath -m "$1")"

    # that_dir=$(realpath -m ${2}; echo x ) ; that_dir=${that_dir%??}
    that_dir="$2"

    result=$(basename_noline "$this_dir")
    if [ "$result" == "$that_dir" ]; then
      echo "matches: basename('$this_dir') = '${that_dir}'"
    else
      echo "Mismatched: basename('$this_dir') != '${that_dir}'; got '${result}'"
      exit 1
    fi
  }

  basename_match "/boot/bzImage.gz" "bzImage.gz"

  basename_match '.'  "test"
  basename_match '..'  "easy-admin"
  basename_match '../'  "easy-admin"
  basename_match '..//'  "easy-admin"

  basename_match '../.'  "easy-admin"
  basename_match '../..' "github"
  basename_match '../a'  "a"

  basename_match '/'  "/"
  basename_match '/..'  "/"
  basename_match '/../'  "/"
  basename_match '/../.'  "/"
  basename_match '../a/.'  "a"
  basename_match '../a/..'  "easy-admin"
  basename_match 'no-such-dir/no-such-file'  "no-such-file"
  echo "Unittest: real_basename_noline(): finished"

  # PWD-influenced Unit Test
  pushd .
  cd / || exit 1
  basename_match '../etc'  "etc"
  cd /etc || exit 1
  basename_match '../etc'  "etc"
  cd /var/tmp || exit 1
  basename_match '../etc'  "etc"
  cd /var/cache || exit 1
  basename_match 'etc/etc/etc/..'  "etc"
  popd || exit 1

  # absolute/relative non-existant subdirs
  basename_match '/no-such-dir/etc/etc/etc/..'  "etc"
  basename_match 'no-such-dir/etc/etc/etc/..'  "etc"
  basename_match 'no-such-dir/../etc/etc/etc/..'  "etc"
  basename_match 'no-such -dir/../etc/etc/etc/..'  "etc"

  # spaces in filespec
  basename_match 'no-such -dir/../etc/etc/etc/..'  "etc"
  basename_match 'no-such-dir/../ etc/etc/etc/..'  "etc"
  basename_match 'no-such-dir/ ../etc/etc/etc/..'  "etc"

  basename_match 'no-such-dir/../etc/etc/etc/ filename_with _space _and tab' \
                " filename_with _space _and tab"
  basename_match 'no-such-dir/../etc/etc/space directory/file' \
                "file"
  basename_match 'no-such-dir/../etc/etc/ space_directory/file' \
                "file"
  basename_match 'no-such-dir/../etc/etc/space_directory /file' \
                "file"
  basename_match 'no-such-dir/../etc/etc/ space directory /file' \
                "file"
  echo "$0: unittest: passed"
fi
