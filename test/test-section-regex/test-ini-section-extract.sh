#!/bin/sh

. ../section-regex.sh

raw_file_read()
{
cat << DATA_EOF | cat
void=unvoided

[default]
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

assert_section_extract() {
  raw_file=$1
  sec=$2
  expected=$3
  note=$4
  ini_buffer="$(ini_file_read "$raw_file")"
  result="$(ini_section_extract "$ini_buffer" "$sec")"
  echo "section: $result"
  if [ "$result" = "$expected" ]; then
    echo "assert_section_extract('$sec'): found: passed: # $note"
  else
    echo "assert_section_extract('$sec'): NOT FOUND # $note"
    echo "  expected: $expected"
    echo "  result  : $result"
    echo "Aborted."
    exit 1
  fi
}

raw_file="$(raw_file_read)"
ini_buffer="$(ini_file_read "$raw_file")"

# assert_section_extract "$ini_buffer" "Default" "$expected" "no-section default DNS"
# assert_section_extract "$ini_buffer" "" "DNS=0.0.0.0" "no-section default DNS"
assert_section_extract "$ini_buffer" "default" "[default]DNS=
[default]DNS=4.4.4.4
[default]void=devoided" "no such 'default' section"
ini_buffer="""[Machine1]

app=version1


[Machine2]

app=version1

app=version2

[Machine3]

app=version1
app=version3
"""
assert_section_extract "$ini_buffer" "Machine1' "" "StackOverflow"
assert_section_extract "$ini_buffer" "Resolve" "[Resolve]DNS=0.0.0.0
[Resolve]void=\"asdf;zxcv\"
[Resolve]DNS=1.1.1.1
[Resolve]FallbackDNS=" "simple"

