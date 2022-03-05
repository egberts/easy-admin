#!/bin/sh

. ../section-regex.sh

raw_file_read()
{
cat << DATA_EOF | cat
void=unvoided

[Default]
DNS=
DNS=4.4.4.4
void=devoided

[Resolve]
DNS=0.0.0.0
void="asdf;zxcv"

[spacey se c t i o n]
Underscore_here_a_lot=123

[space_suffixed ]
space_suffixed1 =123
void=asdf # comment

[ prefixed_space]
 prefixed_space1=123

[underscore_section]
Underscore_here_a_lot=123

[Resolve]
# second Resolve section, it should continue within here and pick up newer value
DNS=1.1.1.1
FallbackDNS=

DATA_EOF
}


assert_section_test() {
  local ini_buffer sec expected note result
  ini_buffer=$1
  sec=$2
  expected=$3
  note=$4
  result="$(ini_section_test "$ini_buffer" "$sec")"
  if [ "$result" = "$expected" ]; then
    echo "assert_section_test('$sec'): found: passed: # $note"
  else
    echo "assert_section_test('$sec'): NOT FOUND # $note"
    echo "Aborted."
    exit 1
  fi
}


# So preloading a file into a variable then do all works against
# this variable is a real time speedup for processing.
#
# performed ini_file_read/ini_section/ini_kv_last_by_section_by_keyword
# for 10 seconds and performed 1900 sets of those three functions;
# or about 570 calls per second. (fast enough for bash)

raw_file="$(raw_file_read)"
ini_buffer="$(ini_file_read "$raw_file")"

expected="[Default]DNS=0.0.0.0
  [Default]DNS=1.1.1.1"
assert_section_test "$ini_buffer" "Resolve" 1 "simple"
assert_section_test "$ini_buffer" "Default" 1 "has 'default'"
assert_section_test "$ini_buffer" "Default" 1 "has 'for a default'"
assert_section_test "$ini_buffer" "underscore_section" 1 "has an underscore"
assert_section_test "$ini_buffer" " prefixed_space" 1 "prefixed spaces"
assert_section_test "$ini_buffer" "space_suffixed " 1 " suffixed spaces"
assert_section_test "$ini_buffer" "spacey se c t i o n" 0 "properly ignores sections w/ mid-space"
echo

echo "${BASH_SOURCE[0]}: Done."

