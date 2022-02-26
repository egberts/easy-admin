#!/bin/bash
# File: dirname_no_line2.sh
# Title: exercise 'dirname' in a POSIX manner
#
# SHELLs Confirmed:
#   yes - bash 5.1.4/Linux/Debian
#   ??? - zsh/MacOS/Catalina

# POSIX basename/dirname do not have --zero/-0, yet
# we must eat the leading '\n' somehow

# syntax: real_dirname_noline <filespec>
# works in all corner cases of filespec
# having a whitespace suffix or prefix,
# or having '.', '..', or '/'.
real_dirname_noline2()
{
  # get full filespec from a simple file
  filespec=${1:A}

  # collapse all '..' and weirdo pathways
  filespec="$(realpath -m "$filespec")"

  # POSIX dirname ALWAYS adds '\n', so we must strip that off
  # strip off the basename from the full filespec, then append 'x'
  dirspec="$(dirname "${filespec}" ; echo x)"

  # strip off both the '\n' and 'x' from result
  dirspec=${dirspec%??}

  # shorter variant
  # dirspec=$(dirname "$filespec" ; echo x); dirspec=${dirspec%??}


  echo "$dirspec"
}

if [ -n "$UNITTEST" ]; then
  echo "Unittest: real_dirname_noline2(): started"

  function dirname_match()
  {
    # this_dir=$(realpath -m ${1}; echo x) ; this_dir=${this_dir%??}
    this_dir="$1"

    # that_dir=$(realpath -m ${2}; echo x ) ; that_dir=${that_dir%??}
    that_dir="$(realpath -m "$2")"

    result=$(real_dirname_noline2 "$this_dir")
    if [ "$result" == "$that_dir" ]; then
      echo "matches: dirname('$this_dir') = '${that_dir}'"
    else
      echo "Mismatched: dirname('$this_dir') != '${that_dir}'; got '${result}'"
      exit 1
    fi
  }

  echo "hereafter, it must have \$PWD: $PWD/.."
  dirname_match "${PWD}/.." "$(realpath "${PWD}/../..")"

  echo "hereafter, it must have ."
  dirname_match '.'  "${PWD}/.."
  dirname_match '..'  "${PWD}/../.."
  dirname_match '../'  "${PWD}/../.."
  dirname_match '..//'  "${PWD}/../.."
  echo "hereafter, it must have .."
  dirname_match '../.'  "${PWD}/../.."
  dirname_match '../..'  "${PWD}/../../.."
  dirname_match '../a'  "${PWD}/.."

  echo "hereafter, it must have /"
  dirname_match '/'  "/"
  dirname_match '/..'  "/"
  dirname_match '/../'  "/"
  dirname_match '/../.'  "/"
  echo "hereafter, it must pass."
  dirname_match '../a/.'  "${PWD}/.."
  dirname_match '../a/..'  "${PWD}/../.."
  dirname_match 'no-such-dir/no-such-file'  "${PWD}/no-such-dir"
  echo "Unittest: real_dirname_noline(): finished"

  # PWD-influenced Unit Test
  pushd .
  cd / || exit 1
  dirname_match '../etc'  "/"
  cd /etc || exit 1
  dirname_match '../etc'  "/"
  cd /var/tmp || exit 1
  dirname_match '../etc'  "/var"
  cd /var/cache || exit 1
  dirname_match 'etc/etc/etc/..'  "/var/cache/etc"
  popd || exit 1

  # absolute/relative non-existant subdirs
  dirname_match '/no-such-dir/etc/etc/etc/..'  "/no-such-dir/etc"
  dirname_match 'no-such-dir/etc/etc/etc/..'  "no-such-dir/etc"
  dirname_match 'no-such-dir/../etc/etc/etc/..'  "etc"
  dirname_match 'no-such -dir/../etc/etc/etc/..'  "etc"

  # spaces in filespec
  dirname_match 'no-such -dir/../etc/etc/etc/..'  "etc"
  dirname_match 'no-such-dir/../ etc/etc/etc/..'  " etc"
  dirname_match 'no-such-dir/ ../etc/etc/etc/..'  "no-such-dir/ ../etc"
  dirname_match 'no-such-dir/../etc/etc/etc/ filename_with _space _and tab' \
                "etc/etc/etc"
  dirname_match 'no-such-dir/../etc/etc/space directory/file' \
                "etc/etc/space directory"
  dirname_match 'no-such-dir/../etc/etc/ space_directory/file' \
                "etc/etc/ space_directory"
  dirname_match 'no-such-dir/../etc/etc/space_directory /file' \
                "etc/etc/space_directory "
  dirname_match 'no-such-dir/../etc/etc/ space directory /file' \
                "etc/etc/ space directory "
  echo "$0: unittest: passed"
fi
