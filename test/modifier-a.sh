#
# Zsh variables have modifiers (that comes after the ':')
# such as in:
#   ${MY_VARIABLE:2} - for starting at thurd character
#   ${MY_VARIABLE:3:1} - for showing just the fourth character
#   ${MY_VARIABLE:a} - for expanding the filespec
#
# But that is not POSIX shell, so 'A' modifier is a no-go around here.
#
#shellcheck disable=SC2148

filespec=$1

filespec_a="$(bash -c 'echo ${0:a}' "$1")"
filespec_A="$(bash -c 'echo ${0:A}' "$1")"

echo "filespec:   $filespec"
echo "filespec_a: $filespec_a"
echo "filespec_A: $filespec_A"

# WUT?  No change in 'modifier'?
echo "realpath: $(realpath -- "$filespec")"
echo "realpath_e: $(realpath -e -- "$filespec")"
echo "realpath_m: $(realpath -m -- "$filespec")"
echo "realpath_L: $(realpath -L -- "$filespec")"
echo "realpath_P: $(realpath -P -- "$filespec")"
