#!/bin/bash
# POSIX basename/dirname do not have --zero/-0, yet we must eat the '\n' somehow

#SCRIPT_NAME="${0:A}"


# syntax: real_dirname_noline <filespec>
# works in all corner cases of filespec
# having a whitespace suffix or prefix,
# or having '.', '..', or '/'.
real_dirname_noline()
{
# Modifiers
# After the optional word designator, you can add a
# sequence of one or more of the following modifiers,
# each preceded by a ‘:’. These modifiers also work
# on the result of --> filename generation <-- and
# --> parameter expansion <--, except where noted.
#
# A
#
#   Turn a file name into an absolute path as the ‘a’
#   modifier does, and then pass the result through
#   the realpath(3) library function to resolve
#   symbolic links.
#
# Note: on systems that do not have a realpath(3)
#       library function, symbolic links are not
#       resolved, so on those systems ‘a’ and ‘A’ are
#       equivalent.
#
# Note: foo:A and realpath(foo) are different on some
#       inputs. For realpath(foo) semantics, see
#       the ‘P‘ modifier.

# Only substitute the '~' (tilde) symbol if it begins
# with '~' to change into '$HOME'.
  filespec="${1/#\~/$HOME}"
  if [ -n "$filespec" ]; then
    b="$(bash -c 'echo ${0:A}' "$filespec")"
    b="$(realpath -m -- "$b")"
    b="$(dirname -- "$b")"
    echo -n "$b"
  else
    echo "dirname: missing operand."
    exit 1
  fi
  #echo "real_dirname_noline: ended"
}

if [ -n "$UNITTEST" ]; then
  echo "Unittest: real_dirname_noline2(): started"

  function dirname_match()
  {
    # this_dir=$(realpath -m -- ${1}; echo x) ; this_dir=${this_dir%??}
    this_dir="$1"

    # that_dir=$(realpath -m -- ${2}; echo x ) ; that_dir=${that_dir%??}
    that_dir="$(realpath -m -- "$2")"

    result=$(real_dirname_noline "$this_dir")
    if [ "$result" == "$that_dir" ]; then
      echo "matches: dirname('$this_dir') = '${that_dir}'"
    else
      echo "Mismatched: dirname('$this_dir') != '${that_dir}'; got '${result}'"
      exit 1
    fi
  }

  echo "hereafter, it must have \$PWD: $PWD/.."
  dirname_match "${PWD}/.." "$(realpath -- "${PWD}/../..")"

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
