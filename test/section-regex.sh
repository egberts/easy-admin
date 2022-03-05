#!/bin/bash
# File: section-regex.sh
# Title: Parse and find keyvalue in the .INI-format v1.4 file
#

# syntax: ini_file_read <raw_buffer>
# outputs: formatted bracket-nested "[section]keyword=keyvalue"
ini_file_read()
{
  local ini_buffer raw_buffer hidden_default
  raw_buffer="$1"
  # somebody has to remove the 'inline' comment
  # Currently does not do nested-quotes within a pair of same single/double
  # quote ... YET:
  #
  # But there is a way, the Regex way that works.
  #
  # Need to find a way to translate this Python regex:
  #
  # (((\x27[ \!\"\#\$\%\&\(\)\*\+\-\.\/0-9\:\;\<\=\>\?@A-Z\[\\\]\^\_\`a-z\|\~]*\x27\s*)|(\"[ \!\#\$\%\&\x27\(\)\*\+\-\.\/0-9\:\;\<\=\>\?@A-Z\[\\\]\^\_\`a-z\|\~]*\"\s*)|(\/([ \!\$\%\&\(\)\*\+\-\.0-9\:\<\=\>\?@A-Z\[\]\^\_\`a-z\|\~]+[ \!\$\%\&\(\)\*\+\-\.0-9\:\<\=\>\?@A-Z\[\]\^\_\`a-z\|\~]*)|([ \!\$\%\&\(\)\*\+\-\.0-9\:\<\=\>\?@A-Z\[\]\^\_\`a-z\|\~]*))*)*)([;#]+)*.*$
  #
  # Above works in https://www.debuggex.com/
  # Tested in https://extendsclass.com/regex-tester.html#pcre
  # Tested in https://www.freeformatter.com/regex-tester.html
  # Tested in https://regexr.com/
  # 
  # 
  raw_buffer="$(echo "$raw_buffer" | sed '
  s|[[:blank:]]*//.*||; # remove //comments
  s|[[:blank:]]*#.*||; # remove #comments
  t prune
  b
  :prune
  /./!d; # remove empty lines, but only those that
         # become empty as a result of comment stripping'
 )"

# awk does the removal of leading and trailing spaces
  ini_buffer="$(echo "$raw_buffer" | awk '/^\[.*\]$/{obj=$0}/=/{print obj $0}')"  # original
  # ini_buffer="$(echo "$raw_buffer" | awk  '/^\[.*\]$/{obj=$0}/=/{gsub(/^\[[ \t]*/, "["); gsub(/[ \t]*\]/, "]"); print obj $0}')"
  ini_buffer="$(echo "$ini_buffer" | sed  's/^\s*\[\s*/\[/')"
  ini_buffer="$(echo "$ini_buffer" | sed  's/\s*\]\s*/\]/')"

  # finds all 'no-section' and inserts '[Default]'
  hidden_default="$(echo "$ini_buffer" \
	          | egrep '^[-0-9A-Za-z_\$\.]+=' | sed 's/^/[Default]/')"
  if [ -n "$hidden_default" ]; then
    echo "$hidden_default"
  fi
  # finds sectional and outputs as-is
  echo "$(echo "$ini_buffer" | egrep '^\[\s*[-0-9A-Za-z_\$\.]+\s*\]')"
}


# syntax: init_section_name_normalize <section_name>
ini_section_name_normalize()
{
  local result
  result="${1#"${1%%[![:space:]]*}"}"
  echo "${result%"${result##*[![:space:]]}"}"
}


# Ensure that the keyword is useable in INI file 
# Syntax: ini_keyword_normalize <unverified_keyword>
# output: <sanitized_keyword>  
# error: none
ini_keyword_normalize()
{
  local sanitized_kw expected_kw
  expected_kw="$1"
  # knock out any and all whitespaces
  sanitized_kw="$(echo "$expected_kw" | sed -- 's/[ \t]//g')"
  sanitized_kw="$(echo "$sanitized_kw" \
	  | sed -- 's/[\~\`\!\@\%\^\*()+=,]//g')"
  # remove pesky hashmark (interferes with bash regex)
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[\#]//g')"
  # remove pesky backslash (interferes with bash regex)
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[\\]//g')"
  # remove pesky brackets (interferes with bash regex)
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[\[]//g')"
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[]]//g')"
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[\{]//g')"
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[\}]//g')"
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[>]//g')"
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[<]//g')"
  sanitized_kw="$(echo "$sanitized_kw" | sed -- 's/[\/]//g')"
  # remove pesky tilde (interferes with bash regex)
  # now only allow alphanum, '-', '_', '$' in keyword
  #sanitized_kw="${sanitized_kw//[^[-a-z0-9_\$.]]/}"
  echo "$sanitized_kw"
}


# Assert that the keyword is valid for use in a INI file.
# Syntax: ini_keyword_valid <unverified_keyword>
# output: silent or '<error-msg>'
# return: 0 (invalid) or 1 (valid)
# error: none
ini_keyword_valid()
{
  local sanitized_kw expected_kw
  expected_kw="$1"
  sanitized_kw="$(ini_keyword_normalize "$expected_kw")"
  # echo "expected_kw: $expected_kw"
  # echo "sanitized_kw: $sanitized_kw"
  if [ "$sanitized_kw" != "$expected_kw" ]; then
    echo "ini_keyword_valid: kw='${expected_kw}' can only be '${sanitized_kw}'"
    return 0
  else
    # silent output necessary for a success
    return 1
  fi
}

# syntax: ini_section_list <ini_buffer>
# output: list of sections encountered
ini_section_list()
{
  local ini_buffer section_names 
  ini_buffer="$1"

  # extract all lines having matching section name
  # section_content is now always defined at this point ('default' or otherwise)
  section_names="$(echo "$ini_buffer" \
                 | grep '^\s*\[' \
		 | awk '{ sub(/.*\[/, ""); sub(/\].*/, ""); print }')"
  section_names="$( echo "$section_names" | sort -u | xargs )"
  echo "$section_names"
}


# syntax: ini_section_extract <ini_buffer> <section_name>
# outputs: selected lines from ini_buffer
ini_section_extract()
{
  local section_name ini_buffer section_name pattern 
  local result normalized_section_name
  # $1 - ini_buffer
  # $2 - section name
  # extract all lines having matching section name
  ini_buffer="$1"
  section_name="$2"
  normalized_section_name="$(ini_section_name_normalize "$section_name")"
  pattern="${normalized_section_name}"
  result="$(echo "$ini_buffer" | egrep -- "^\[${normalized_section_name}\]")"
  echo "${result}"
}



# Syntax: ini_section_test <ini_buffer> <section_name>
# return: $?  1 or 0
ini_section_test()
{
  local result
  result="$(ini_section_extract "$1" "$2")"
  if [ -n "$result" ]; then
    echo 1
  else
    echo 0
  fi
}

# Syntax: ini_section_read <ini_buffer> <section_name>
# return: <ini_buffer>
ini_section_read()
{
  local result
  result="$(echo "$1" | grep '^[-a-zA-Z09_\$\.]\=')"
  echo "result: $result"
  if [ -n "$result" ]; then
    return 1
  else
    return 0
  fi
}


# Syntax: init_kw_get <ini_buffer> <section_name> <keyword>
ini_kw_get()
{
  local ini_buffer section keyword ini_by_section found_keyline found_keylines kv
  ini_buffer="$1"
  # echo "ini_buffer: $ini_buffer"
  section="$2"
  # echo "section: $section"
  keyword="$3"
  ini_keyword_valid "$keyword"
  # get all matching section
  ini_by_section="$(ini_section_extract "$ini_buffer" "$section")"
  #echo "ini_by_section: $ini_by_section"
  found_keylines="$(echo "$ini_by_section" \
	  | egrep "^\[\S+\]\s*${keyword}\s*=" )"

  # echo "found_kls: $found_keylines "
  found_keyline="$(echo "$found_keylines" | tail -n1 )"
  # echo "found_kl: $found_keyline "
  kv="$(echo "$found_keyline" | awk -F= '{print $2}')"
  # remove inline comments
  #
  #
  # into BASH, for now, do simple removal of inline comment
  kv="$(echo "$kv" | sed "/^\s*;/d;s/\s*;[^\"']*$//")"
  # echo "kv2: $kv"
  kv="$(echo "$kv" | sed "/^\s*#/d;s/\s*#[^\"']*$//")"
  # echo "kv4: $kv"
  kv="$(echo "$kv" | sed "/^\s*\/\//d;s/\s*\/\/[^\"']*$//")"
  # echo "kv5: $kv"

  # remove surrounding whitespaces
  kv="$(echo "$kv" | sed -- 's/^\s*//')"
  kv="$(echo "$kv" | sed -- 's/\s*$//')"
  echo "$kv"
}

# Syntax: init_kw_test <ini_buffer> <section_name> <keyword>
# outputs: 1 or 0
ini_key_test()
{
  local retsts
  if [ -n "$(ini_kw_get "$1" "$2" "$3")" ]; then
    retsts=1
  else
    retsts=0
  fi
  return $retsts
}
