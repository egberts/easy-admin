
# POSIX basename/dirname do not have --zero/-0, yet we must eat the '\n' somehow

SCRIPT_NAME="${0:A}"

my_dirname()
{
  #echo "my_dirname: started"
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
  if [ -n "$1" ]; then
    b="$(bash -c 'echo ${0:A}' "$1")"
    b="$(dirname -- "$b")"
    echo "$SCRIPT_NAME: my_dirname: $b"
  fi
  #echo "my_dirname: ended"
}

my_basename()
{
  #echo "my_basename: started"
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
  if [ -n "$1" ]; then
    b="$(basename -- "$1")"
  else
    echo "my_basename: empty arg"
  fi
  #echo "my_basename: ended"
}

function show_dirname()
{
  #echo "show_dirname: started"
  b="$(bash -c 'echo ${0:A}' "$SCRIPT_NAME")"
  echo -n "\${0:A}: "; my_dirname "$b"
  b="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
  echo -n "pwd-approach: "; my_dirname "$b"

  echo -n "BASH_SOURCE[0]: "; my_dirname "${BASH_SOURCE[0]}"
  echo -n "BASH_SOURCE[1]: "; my_dirname "${BASH_SOURCE[1]}"
  echo -n "BASH_SOURCE[2]: "; my_dirname "${BASH_SOURCE[2]}"
  #echo "show_dirname: ended"
}

function show_basename()
{
  #echo "show_basename: started"
  b="$(bash -c 'echo ${0:A}' "$SCRIPT_NAME")"
  echo -n "\${0:A}: "; my_basename "$b"

  if [ -n "${BASH_SOURCE[0]}" ]; then
    b="${BASH_SOURCE[0]}"
    b="$(basename -- "$b")"
    # b="$(cd "$b" &>/dev/null && pwd -P)"  # that one creepingly exited out with 1
  else
    echo "exit 3"
    exit 3
  fi
  echo -n "pwd-approach: "; my_basename "$b"
  echo -n "BASH_SOURCE[0]: "; my_basename "${BASH_SOURCE[0]}"
  echo -n "BASH_SOURCE[1]: "; my_basename "${BASH_SOURCE[1]}"
  echo -n "BASH_SOURCE[2]: "; my_basename "${BASH_SOURCE[2]}"
  #echo "show_basename: ended"
}

function show_me()
{
  this_script_is_located_in_this_dir="$(cd "$(dirname -- "${BASH_SOURCE[1]}")" &>/dev/null && pwd -P)"
  echo "This script is in: $this_script_is_located_in_this_dir"
  echo "Yet it shows \$0: as: $SCRIPT_NAME"
}

# We choose the most POSIX variant of 'dirname'/'basename'
echo "Before dir: $PWD"
script_is_located_in_this_dir="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
echo "After dir: $PWD"

show_me
# show_basename
# show_dirname
source "${script_is_located_in_this_dir}/test-dir/script-in-subdir.sh"

show_me

