#  no hash-tag here
#
# File: source-me.sh
# Title: An example file to be sourced by other shell scripts

echo "This file $(basename -- "${BASH_SOURCE[0]}") got sourced by ${BASH_SOURCE[1]}"
set

this_script_fullfilespec="$(realpath -e $0)"
this_script_dirpath="$(dirname -- "$this_script_fullfilespec")"

find_my_call_stack_filespec="${this_script_dirpath}/call-stack-trace.sh"
source "$find_my_call_stack_filespec"

echo "MY_PATH: $MY_PATH"

echodbg "An echodbg exercise in bash call stack dump; re-run with 'DEBUG=1' prepended"
echomsg "An echomsg exercise in bash call stack dump; re-run with 'DEBUG=1' prepended"
echowarn "An echowarn exercise in bash call stack dump; re-run with 'DEBUG=1' prepended"
echoinfo "An echoinfo exercise in bash call stack dump; re-run with 'DEBUG=1' prepended"
fatalerr "An fataerr exercise in bash call stack dump; re-run with 'ANSI_COLOR=1 DEBUG=1' prepended"
