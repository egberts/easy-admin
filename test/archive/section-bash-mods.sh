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



function raw_file_read()
{
  echo "$(\
cat << DATA_EOF | cat
[default]
DNS=
DNS="4.4.4.4"

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
)"
}

function ini_file_read()
{
    echo "$1" | awk '/^\[.*\]$/{obj=$0}/=/{print obj $0}' 
}

# Syntax: ini_section <section_name>
function ini_section()
{
  section_name="$(ini_section_name_normalize "$2")"
  echo "$1" \
      | awk '/^\[.*\]$/{obj=$0}/=/{print obj $0}' \
      | grep '^\['${section_name}'\]' 
}

# Syntax: ini_kv_last_by_section_by_keyword <section> <keyword>
function ini_kv_get_by_awk_grep_awk()
{
  section_name="$(ini_section_name_normalize "$2")"
  keyword="$(ini_section_name_normalize "$3")"
  echo "$1" \
      | awk '/^\[.*\]$/{obj=$0}/=/{print obj $0}' \
      | grep '^\['${section_name}'\]'${keyword}'=' \
      | awk -F= '{print $2}' | tail -n1
}

function ini_section_name_normalize()
{
  # zero-shell normalizer
  ini="$1"                # read the argument
  IFS=$'\n'
  ini="${ini//;*/}"       # remove comments with ;
  ini=${ini/\    =/=}  # remove tabs before =
  ini=${ini/=\   /=}   # remove tabs be =
  ini="${ini#"${ini%%[![:space:]]*}"}"  # remove leading spaces
  ini="${ini%"${ini##*[![:space:]]}"}"  # remove trailing spaces
  echo "$ini"
}

# Syntax: ini_kv_last_by_section_by_keyword <section> <keyword>
function ini_kv_get_all_by_awk()
{
    echo "$1" | awk -v section="$2" -v key="$3" '
        BEGIN {
        if (length(key) > 0) { params=2 }
        else if (length(section) > 0) { params=1 }
        else { params=0 }
        }
        match($0,/;/) { next }
        match($0,/#/) { next }
        match($0,/^\[(.+)\]$/){
        current=substr($0, RSTART+1, RLENGTH-2)
        found=current==section
        if (params==0) { print current }
        }
        match($0,/(.+)=(.+)/) {
        if (found) {
            if (params==2 && key==substr($1, 0, length(key))) { print substr($0, length(key)+2) }
            if (params==1) { printf "%s\n",$1,$3 }
        }
    }'
}


if [ -n "$UNITTEST" ]; then
  match_section_name_normalize()
  {
    dkw="$(ini_section_name_normalize "$1")"
    if [ "$dkw" == "$2" ]; then
      echo "'$1' result '$dkw', pass	# $3"
    else
      echo "'$1' result '$dkw', NOT MATCH '$2'	# $3"
      echo "aborted."
      exit 1
    fi
  }

  raw_file="$(raw_file_read)"

  # So preloading a file into a variable then do all works against 
  # this variable is a real time speedup for processing.
  #
  # performed ini_file_read/ini_section/ini_kv_last_by_section_by_keyword
  # for 10 seconds and performed 1900 sets of those three functions;
  # or about 570 calls per second. (fast enough for bash)

  match_section_name_normalize 'Resolve' 'Resolve' "plain string"
  match_section_name_normalize 'Re_solve' 'Re_solve' "underscore"
  match_section_name_normalize '-Resolve' '-Resolve' "dash symbol, prefix"
  match_section_name_normalize 'Re-solve' 'Re-solve' "dash symbol, middle"
  match_section_name_normalize 'Resolve-' 'Resolve-' "dash symbol, suffix"
  match_section_name_normalize 'Re$solve' 'Re$solve' "dollar sign"
  match_section_name_normalize "Re\$solve" 'Re$solve' "dollar sign, double-quoted"
  match_section_name_normalize 'Re*solve' 'Re*solve' "asterisk"
  match_section_name_normalize ' Resolve' 'Resolve' "space-prefixed"
  match_section_name_normalize 'Resolve ' 'Resolve' "space-suffixed"
  match_section_name_normalize ' Resolve ' 'Resolve' "space-surrounded"
  match_section_name_normalize '     Resolve' 'Resolve' "multi-space prefixed"
  match_section_name_normalize 'Resolve     ' 'Resolve' "multi-space suffixed"
  match_section_name_normalize 'Re    solve' 'Re    solve' "multi-space middle"
  match_section_name_normalize '	Resolve' 'Resolve' "tab prefixed"
  match_section_name_normalize 'Resolve	' 'Resolve' "tab suffixed"
  match_section_name_normalize 'Re	solve	' 'Re	solve' "tab middle"

  # performance test
  idx=10000
  echo "Performing $idx iterations ..."
  test_section_name="default"
  time while [ $idx -ge 0 ]; do
    dkw="$(ini_section_name_normalize "$test_section_name")"
    ((idx--))
  done
  # string only, 6.5s @ 10,000 or 300/s
  # with a simple echo, 4.8s @ 10,000  
  echo "Unittest passed."
  exit 0
fi


ini_file="$(ini_file_read "$raw_file")"
echo "Entire INI file (encoded): $ini_file"
echo

specific_section="Resolve"
# echo "Attempting to list a specific '$specific_section' section"
result="$(ini_section "$ini_file" "$specific_section")"
echo "ini_section: $result"
# echo "End of specific section in an INI file."
echo

specific_section="Resolve"
specific_keyword="DNS"
# echo "Attempting to list all '$specific_keyword' keyword "
# echo "for a specific '$specific_section' section"
result="$( ini_kv_get_by_awk_grep_awk "$ini_file" "$specific_section" "$specific_keyword")"
echo "ini_kv_: $result"
# echo "End of specific '$specific_keyword' keyword in '$specific_section' section in an INI file."
echo

specific_section="Resolve"
specific_keyword="DNS"
# echo "Attempting to list all '$specific_keyword' keyword "
# echo "for a specific '$specific_section' section"
result="$( ini_kv_get_all_by_awk "$raw_file" "$specific_section" "$specific_keyword")"
echo "ini_kv_: $result"
# echo "End of specific '$specific_keyword' keyword in '$specific_section' section in an INI file."
echo
exit

specific_section="default"
specific_keyword="void"
# echo "Attempting to list all '$specific_keyword' keyword "
# echo "for a specific '$specific_section' section"
result="$( ini_kv_get_all_by_awk "$raw_file" "$specific_section" "$specific_keyword")"
echo "ini_kv_: $result"
# echo "End of specific '$specific_keyword' keyword in '$specific_section' section in an INI file."
echo

specific_section="Resolve"
specific_keyword="void"
# echo "Attempting to list all '$specific_keyword' keyword "
# echo "for a specific '$specific_section' section"
result="$( ini_kv_get_all_by_awk "$raw_file" "$specific_section" "$specific_keyword")"
echo "ini_kv_: $result"
# echo "End of specific '$specific_keyword' keyword in '$specific_section' section in an INI file."
echo


