#!/bin/bash
#
# Fastest way to remove the leading spaces and trailing spaces
# without forking a shell into 'awk', 'grep', or 'sed':
# using parameter expansions in bash variable.
#
# Possibly written in the most POSIX-compliant 
# (IEEE Std 1003.1, 2004 edition) shell, so far.
#
# About 350x/sec.

# syntax: remove_prefix_spaces <string>
# return: a string via output (fd=1)
remove_prefix_spaces()
{
  # remove leading whitespace characters
  echo "${1#"${1%%[![:space:]]*}"}"
}

# syntax: remove_suffix_spaces <string>
# return: a string via output (fd=1)
remove_suffix_spaces()
{
  # remove trailing whitespace characters
  echo "${1%"${1##*[![:space:]]}"}"
}

# syntax: remove_surrounding_spaces <string>
# return: a string via output (fd=1)
remove_surrounding_spaces()
{
  result="$(remove_prefix_spaces "$1")"
  result="$(remove_suffix_spaces "$result")"
  echo "$result"
}

if [ -n "$UNITTEST" ]; then
  # syntax: match_expected_string <string> <expected_str> <test_note_string>
  match_expected_string()
  {
    string="$1"
    expected_string="$2"
    result="$(remove_surrounding_spaces "$string")"
    if [ "$result" == "$expected_string" ]; then
      echo "funcx('$string'): '$result': passes  #	$3"
    else
      echo "funcx('$string'): '$result': failed against expected '$expected_string'	# $3"
    fi
    # unittest
    if [ "${result:0:1}" == ' ' ]; then
      echo "failed to remove prefixed space in '$string'; aborted"
      exit 1
    fi
    if [ "${result: -1}" == ' ' ]; then
      echo "failed to remove suffixed space in '$string'; aborted"
      exit 1
    fi
  }
  match_expected_string 'Resolve' 'Resolve' "plain string"
  match_expected_string 'Re_solve' 'Re_solve' "underscore"
  #shellcheck disable=SC2016
  match_expected_string 'Re$solve' 'Re$solve' "dollar sign"
  #shellcheck disable=SC2016
  match_expected_string "Re\$solve" 'Re$solve' "dollar sign, double-quoted"
  match_expected_string 'Re*solve' 'Re*solve' "asterisk"
  match_expected_string ' Resolve' 'Resolve' "space-prefixed"
  match_expected_string 'Resolve ' 'Resolve' "space-suffixed"
  match_expected_string ' Resolve ' 'Resolve' "space-surrounded"
  match_expected_string '     Resolve' 'Resolve' "multi-space prefixed"
  match_expected_string 'Resolve     ' 'Resolve' "multi-space suffixed"
  match_expected_string 'Re    solve' 'Re    solve' "multi-space middle"
  match_expected_string '	Resolve' 'Resolve' "tab prefixed"
  match_expected_string 'Resolve	' 'Resolve' "tab suffixed"
  match_expected_string 'Re	solve	' 'Re	solve' "tab middle"
  echo "Unittest passed."
  exit 0
fi
