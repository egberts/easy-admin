#
# what-is-my-script-name.sh
#
# This script will find out the current script name is
# regardless of whether it was 'bash', 'source', or directly
# executed.
#
# Tested with all known corner cases:
#    Script is in '..', executed from other PWD
#    Executed from '..', script is located elsewhere
#    Script is in '.', executed from other PWD
#    Executed from '.', script is located elsewhere
#    Script is in '/', executed from other PWD
#    Executed from '/', script is located elsewhere
#
#shellcheck disable=SC2148  # ignore shebang at line 1

# You cannot put BASH_SOURCE[0] inside a function and stored
# in a different script file; so for this to work,
# BASH_SOURCE[0] must be called in the script it is running in
my_script_name="${BASH_SOURCE[0]}"



# Bash variable ':A' or ':a' modifier (to be used
# inside the ${0:A}, only works with $0 ... so far.

# following snippet will not work:
#   my_absolute_script_name="$(bash -c 'echo ${0:a}' "$my_script_name")"

# so we move on to 'basename'/'dirname'

# Try to leverage $PWD to capture absolute path but
# dirname emits an extra '\n' so we cannot use the following snippet:
#    my_absolute_script_name="$(cd "$(dirname -- "$1")"; pwd -P)/$(basename "$1")"

# Since POSIX dirname ALWAYS adds '\n', so we must strip that off as well.
# safely use 'dirname'; same goes for 'realpath' and 'basename'

# Also quoted string fails with '\n' in directory names in next snippet
#     scratchstr="$(dirname -- "${my_script_name}")x"

# So, we go POSIX shell.
scratchstr=$(dirname -- "${my_script_name}" ; echo x )
parentdir="${scratchstr%??}"

if [ -d "${my_script_name}" ]; then
  my_absolute_script_name="$(cd "${my_script_name}" && pwd)"
elif [ -d "${parentdir}" ]; then
  # Since POSIX basename ALWAYS adds '\n', so we must strip that off as well.
  # safely use 'basename'
  scratchstr=$(basename -- "${my_script_name}"; echo x)
  basenamefile="${scratchstr%??}"
  my_absolute_script_name="$(cd "${parentdir}" && pwd)/$basenamefile"
fi
echo "This script name: $my_script_name"
echo "Divided into Relative notation:"
echo "  file name:   $(basename -- "$my_script_name")"
echo "  location:    $(dirname -- "$my_script_name")"
echo "Expanded to Absolute notation:"
echo "  script name: $my_absolute_script_name"
echo "  file name:   $(basename -- "$my_absolute_script_name")"
echo "  location:    $(dirname -- "$my_absolute_script_name")"

source "$(dirname -- "$my_absolute_script_name")/test-dir/script-in-subdir.sh"

unset scratchstr
unset basenamefile
unset my_script_name my_absolute_script_name
