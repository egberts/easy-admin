#!/bin/bash

# Handle the .INI-formatted file

# #  List all [sections] of a .INI file
# sed -n 's/^[ \t]*\[\(.*\)\].*/\1/p'
# 
# #  Read KEY from [SECTION]
# sed -n '/^[ \t]*\[SECTION\]/,/\[/s/^[ \t]*KEY[ \t]*=[ \t]*//p'
# 
# #  Read all values from SECTION in a clean KEY=VALUE form
# sed -n '/^[ \t]*\[SECTION\]/,/\[/s/^[ \t]*\([^#; \t][^ \t=]*\).*=[ \t]*\(.*\)/\1=\2/p'
# 

# sed -nr '/\[section\]/,/\[.*\]/{/keyword/s/(.*)=(.*)/\2/p}'

# awk -F'=' -v section="[section_name]" -v k="keyword"  '
# $0==section{ f=1; next }  # Enable a flag when the line is like your section
# /\[/{ f=0; next }         # For any lines with [ disable the flag
# f && $1==k{ print $0 }    # If flag is set and first field is the key print key=value
# ' ini.file




# syntax: ini_file_read <raw_buffer>
# outputs: formatted bracket-nested "[section]keyword=keyvalue"
ini_file_read()
{
  local ini_buffer raw_buffer hidden_default
  raw_buffer="$1"
  # somebody has to remove the 'inline' comment
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
	          | egrep -- '^[a-zA-Z\-_\$]+=' | sed 's/^/[Default]/')"
  if [ -n "$hidden_default" ]; then
    echo "$hidden_default"
  fi
  # finds sectional and outputs as-is
  # echo "$(echo "$ini_buffer" | egrep -- '^\[[a-zA-Z\-_\$]+\]')"
  echo "$(echo "$ini_buffer" | egrep -- '^\[\s*[A-Za-z\-_\$]+\s*\]')"
}


# syntax: init_section_name_normalize <section_name>
ini_section_name_normalize()
{
  local result
  result="${1#"${1%%[![:space:]]*}"}"
  echo "${result%"${result##*[![:space:]]}"}"
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
                 | grep -- '^\s*\[' \
		 | awk '{ sub(/.*\[/, ""); sub(/\].*/, ""); print }')"
  section_names="$( echo "$section_names" | sort -u | xargs )"
  echo "$section_names"
}


# syntax: ini_section_extract <ini_buffer> <section_name>
# outputs: selected lines from ini_buffer
ini_section_extract()
{
  local section_name
  # $1 - ini_buffer
  # $2 - section name
  # extract all lines having matching section name
  ini_buffer="$1"
  section_name="$2"
  normalized_section_name="$(ini_section_name_normalize "$section_name")"
  pattern="${normalized_section_name}"
  result="$(echo "$ini_buffer" | egrep -- "\[${normalized_section_name}\]")"
  echo "${result}"
  result="$result"
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
  # two part: undefined section and 'default' section
  # part one: extract undefined section
  result="$(echo "$1" | grep '^[a-zA-Z09\-_\$]\=')"
  echo "result: $result"
  if [ -n "$result" ]; then
    return 1
  else
    return 0
  fi
}



