#!/bin/sh

. ../section-regex.sh

assert_section_list() {
  raw_file=$1
  expected=$2
  note=$3
  ini_buffer="$(ini_file_read "$raw_file")"
  result="$(ini_section_list "$ini_buffer")"
  echo "section: $result"
  if [ "$result" = "$expected" ]; then
    echo "assert_section_list(): found: passed: # $note"
  else
    echo "assert_section_list(): NOT FOUND # $note"
    echo "Aborted."
    exit 0
  fi
}

raw_file="$(
  cat <<TEST_EOF
DNS=
TEST_EOF
)"
assert_section_list "$raw_file" "Default" "Empty keyvalue"

raw_file="$(
  cat <<TEST_EOF
DNS=0.0.0.0
TEST_EOF
)"
assert_section_list "$raw_file" "Default" "default"

raw_file="$(
  cat <<TEST_EOF
DNS=
DNS=0.0.0.0
TEST_EOF
)"
assert_section_list "$raw_file" "Default" "mixed default"

raw_file="$(
  cat <<TEST_EOF
[Default]
DNS=
TEST_EOF
)"
assert_section_list "$raw_file" "Default" "default empty-keyvalue"

raw_file="$(
  cat <<TEST_EOF
[Default]
DNS=1.1.1.1
TEST_EOF
)"
assert_section_list "$raw_file" "Default" "standard"

raw_file="$(
  cat <<TEST_EOF
[Default]
DNS = 2.2.2.2
TEST_EOF
)"
assert_section_list "$raw_file" "Default" "leading spaces"

raw_file="$(
  cat <<TEST_EOF
DNS=0.0.0.0
[Default]
DNS=1.1.1.1
TEST_EOF
)"
assert_section_list "$raw_file" "Default" "mixed default sections"

raw_file="$(
  cat <<TEST_EOF
[Default]DNS=0.0.0.0
TEST_EOF
)"
assert_section_list "$raw_file" "Default" "[Default]"

raw_file="$(
  cat <<TEST_EOF
[Default]DNS=0.0.0.0
[Default]DNS=1.1.1.1
[Resolve]
TEST_EOF
)"

# empty section do not get an entry in our internal 'ini_buffer'
assert_section_list "$raw_file" "Default" "empty section"

ini_buffer="$(
  cat <<TEST_EOF
DNS=0.0.0.0
  DNS=0.0.0.1
[Unknown]
DNS =0.0.0.2
DNS= 0.0.0.3
[Resolve]
DNS=0.0.0.4
DNS = 0.0.0.5
  DNS     =     0.0.0.6
[Network]
D\$NS=0.0.0.7
D_NS=0.0.0.8
D-NS=0.0.0.9
[Default]DNS=1.1.1.1
TEST_EOF
)"

assert_section_list "$ini_buffer" "Default Network Resolve Unknown" "no-section no-default"
echo

echo "${BASH_SOURCE[0]}: Done."

