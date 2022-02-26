
# POSIX basename/dirname do not have --zero/-0, yet we must eat the '\n' somehow

SCRIPT_NAME="${0:A}"

source dirname_noline.sh

basename_no_line()
{
  #echo "basename_no_line: started"
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
    echo "basename: missing operand."
    exit 1
  fi
  #echo "basename_no_line: ended"
}

function show_dirname()
{
  #echo "show_dirname: started"
  b="$(bash -c 'echo ${0:A}' "$SCRIPT_NAME")"
  echo -n "\${0:A}: "; real_dirname_noline "$b"
  b="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
  echo -n "pwd-approach: "; real_dirname_noline "$b"

  echo -n "BASH_SOURCE[0]: "; real_dirname_noline "${BASH_SOURCE[0]}"
  echo -n "BASH_SOURCE[1]: "; real_dirname_noline "${BASH_SOURCE[1]}"
  echo -n "BASH_SOURCE[2]: "; real_dirname_noline "${BASH_SOURCE[2]}"
  #echo "show_dirname: ended"
}

function show_basename()
{
  #echo "show_basename: started"
  b="$(bash -c 'echo ${0:A}' "$SCRIPT_NAME")"
  echo -n "\${0:A}: "; basename_no_line "$b"

  if [ -n "${BASH_SOURCE[0]}" ]; then
    b="${BASH_SOURCE[0]}"
    b="$(basename -- "$b")"
    # b="$(cd "$b" &>/dev/null && pwd -P)"  # that one creepingly exited out with 1
  else
    echo "exit 3"
    exit 3
  fi
  echo -n "pwd-approach: "; basename_no_line "$b"
  echo -n "BASH_SOURCE[0]: "; basename_no_line "${BASH_SOURCE[0]}"
  echo -n "BASH_SOURCE[1]: "; basename_no_line "${BASH_SOURCE[1]}"
  echo -n "BASH_SOURCE[2]: "; basename_no_line "${BASH_SOURCE[2]}"
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

