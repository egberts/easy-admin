#
# what-is-my-script-name.sh
#
# This script will find out the current script name
# regardless of whether it was 'bash', 'source', or directly
# executed.

my_script_name="${BASH_SOURCE[0]}"

# Bash variable ':A' or ':a' modifier (to be used
# inside the ${0:A}, only works with $0 ... so far.
# so we move on to 'basename'/'dirname' combo to capture absolute path
# following snippet will not work:
#   my_absolute_script_name="$(bash -c 'echo ${0:a}' "$my_script_name")"

# dirname emits an extra '\n' so we cannot use the following snippet:
#    my_absolute_script_name="$(cd "$(dirname -- "$1")"; pwd -P)/$(basename "$1")"

# Since POSIX dirname ALWAYS adds '\n', so we must strip that off as well.
# safely use 'dirname'

# Also quoted string fails with '\n' in directory names, so try next snippet
#     scratchstr="$(dirname -- "${my_script_name}")x"
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
echo "  file name:   $(basename $my_script_name)"
echo "  location:    $(dirname $my_script_name)"
echo "Expanded to Absolute notation:"
echo "  script name: $my_absolute_script_name"
echo "  file name:   $(basename $my_absolute_script_name)"
echo "  location:    $(dirname $my_absolute_script_name)"
unset my_script_name my_absolute_script_name
