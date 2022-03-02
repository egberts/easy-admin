#!/bin/sh

. ../section-regex.sh

# Syntax: assert_file_read <raw_buffer> <expected_string> <unittest_note>
assert_file_read() {
  local raw_buffer sec expected note result
  raw_buffer=$1
  expected=$2
  note=$3
  ini_buffer="$(ini_file_read "$raw_buffer")"
  if [ "$ini_buffer" = "$expected" ]; then
    echo "assert_file_read(): found: passed: # $note"
  else
    echo "assert_file_read(): NOT FOUND # $note"
    echo "Aborted."
    exit 1
  fi
}

assert_file_read ";" "" "comment ;"
assert_file_read "#" "" "comment #"
assert_file_read "DNS=" "[Default]DNS=" "no-section no-value"
assert_file_read "DNS=   # inline comment" "[Default]DNS=" "no-section no-value inline-comment"
assert_file_read "[Default]
DNS=" "[Default]DNS=" "section no-value"
assert_file_read "[Default]
DNS=4.4.4.4" "[Default]DNS=4.4.4.4" "section keyvalue"
assert_file_read "[Default]
DNS=\"4.4.4.4\"" "[Default]DNS=\"4.4.4.4\"" "section keyvalue"
assert_file_read "[ prefixed_space]DNS=" "[prefixed_space]DNS=" "prefixed-space no-value"

assert_file_read "[ prefixed_space]DNS=" "[prefixed_space]DNS=" "prefixed-space no-value"
