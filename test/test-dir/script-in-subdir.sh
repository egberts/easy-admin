#
# script-in-subdir.sh

echo "I am literally in script-in-subdir.sh script now"

SCRIPT_NAME="${BASH_SOURCE[0]}"

my_script_name="${BASH_SOURCE[0]}"
scratchstr=$(dirname -- "${my_script_name}" ; echo x )
parentdir="${scratchstr%??}"
if [ -d "${my_script_name}" ]; then
  my_absolute_script_name="$(cd "${my_script_name}" && pwd)"
elif [ -d "${parentdir}" ]; then
  scratchstr=$(basename -- "${my_script_name}"; echo x)
  basenamefile="${scratchstr%??}"
  my_absolute_script_name="$(cd "${parentdir}" && pwd)/$basenamefile"
fi

echo "This script name: $my_script_name"
echo "Divided into Relative notation:"
echo "  file name:   $(basename "$my_script_name")"
echo "  location:    $(dirname "$my_script_name")"
echo "Expanded to Absolute notation:"
echo "  script name: $my_absolute_script_name"
echo "  file name:   $(basename "$my_absolute_script_name")"
echo "  location:    $(dirname "$my_absolute_script_name")"

EXPECTED_SCRIPT_NAME="script-in-subdir.sh"
ACTUAL_SCRIPT_NAME="$(basename -- "${0:A}")"

# Weird thing about BASH_SOURCE[0] is that we cannot nest this
# into a function and declare it elsewhere or this will misreport!
ACTUAL_SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"

echo "My script name is: $ACTUAL_SCRIPT_NAME"
if [ "$ACTUAL_SCRIPT_NAME" != "$EXPECTED_SCRIPT_NAME" ]; then
  echo "\"${ACTUAL_SCRIPT_NAME}\" is Not an expected script \"${EXPECTED_SCRIPT_NAME}\" name"
  set | grep BASH
  exit 1
fi

