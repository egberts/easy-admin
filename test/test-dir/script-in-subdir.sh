#
# script-in-subdir.sh

echo "I am in script-in-subdir.sh script now"
echo
show_me
# show_basename
# show_dirname

EXPECTED_SCRIPT_NAME="script-in-subdir.sh"
ACTUAL_SCRIPT_NAME="$(basename -- "${0:A}")"
ACTUAL_SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"

echo "My script name is: $ACTUAL_SCRIPT_NAME"
if [ "$ACTUAL_SCRIPT_NAME" != "$EXPECTED_SCRIPT_NAME" ]; then
  echo "\"${ACTUAL_SCRIPT_NAME}\" is Not an expected script \"${EXPECTED_SCRIPT_NAME}\" name"
  set
  exit 1
fi

