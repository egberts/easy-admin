#!/bin/sh

. ../section-regex.sh

assert_kw_get_raw() {
  raw_file=$1
  section=$2
  kw=$3
  expected=$4
  note=$5
  ini_keyword_valid "$kw"
  if [ $? -eq 0 ]; then
    echo "invalid keyword: '$kw'; aborted"
    exit 0
  fi
  ini_buffer="$(ini_file_read "$raw_file")"
  #echo "assert_kw_get: ini_buffer: $ini_buffer"
  echo -n "assert_kw_get_raw('${section}' '${kw}')='$expected': "
  found_kws="$(ini_kw_get "$ini_buffer" "$section" "$kw")"
  echo -n "'${found_kws}' "
  if [ "$found_kws" = "$expected" ]; then
    echo "matched	# $note"
  else
    echo "NOT MATCHED	# $note"
    echo "  result  : '${found_kws}'"
    echo "  expected: '${expected}'"
    echo "Aborted."
    exit 0
  fi
}

assert_kw_get() {
  ini_buffer=$1
  section=$2
  kw=$3
  expected=$4
  note=$5
  ini_keyword_valid "$kw"
  if [ $? -eq 0 ]; then
    echo "invalid keyword: '$kw'; aborted"
    exit 0
  fi
  echo -n "assert_kw_get('${section}' '${kw}')='$expected': "
  found_kws="$(ini_kw_get "$ini_buffer" "$section" "$kw")"
  echo -n "'${found_kws}' "
  if [ "$found_kws" = "$expected" ]; then
    echo "matched	# $note"
  else
    echo "NOT MATCHED	# $note"
    echo "  result  : '${found_kws}'"
    echo "  expected: '${expected}'"
    echo "Aborted."
    exit 0
  fi
}

raw_file="$(
  cat <<TEST_EOF
DNS=0.0.0.0
TEST_EOF
)"
assert_kw_get_raw "$raw_file" "Default" "DNS" "0.0.0.0" "no-section basic"

raw_file="$(
  cat <<TEST_EOF
DNS=
DNS=0.0.0.0
TEST_EOF
)"
assert_kw_get_raw "$raw_file" "Default" "DNS" "0.0.0.0" "no-section duplicate KWs"
raw_file="$(
  cat <<TEST_EOF
DNS=0.0.0.0
DNS=
TEST_EOF
)"
assert_kw_get_raw "$raw_file" "Default" "DNS" "" "no-section duplicate KWs (reversed)"

raw_file="$(
  cat <<TEST_EOF
[Default]
DNS=
TEST_EOF
)"
assert_kw_get_raw "$raw_file" "Default" "DNS" "" "default-section empty-keyvalue"

raw_file="$(
  cat <<TEST_EOF
[Default]
DNS=1.1.1.1
TEST_EOF
)"
assert_kw_get_raw "$raw_file" "Default" "DNS" "1.1.1.1" "default-section standard"

raw_file="$(
  cat <<TEST_EOF
[Default]
DNS = 2.2.2.2
TEST_EOF
)"
assert_kw_get_raw "$raw_file" "Default" "DNS" "2.2.2.2" "default-section surrounding spaces"

raw_file="$(
  cat <<TEST_EOF
DNS=3.3.3.3
[Default]
DNS=4.4.4.4
TEST_EOF
)"
assert_kw_get_raw "$raw_file" "Default" "DNS" "4.4.4.4" "no-section/default-section override"

# end of raw-file-format subtest

# begin of ini-file-format subtest

assert_kw_get "" "Default" "DNS" "" "empty ini_file"
assert_kw_get "
" "Default" "DNS" "" "new line"
assert_kw_get "#" "Default" "DNS" "" "hash mark no-comment"
assert_kw_get ";" "Default" "DNS" "" "semicolon no-comment"
assert_kw_get "//" "Default" "DNS" "" "slash-slash no-comment"
assert_kw_get "# inline comment" "Default" "DNS" "" "hash mark comment"
assert_kw_get "; inline comment" "Default" "DNS" "" "semicolon comment"
assert_kw_get "// inline comment" "Default" "DNS" "" "slash-slash comment"

ini_file="# comment line
[Default]DNS=5.5.5.5
[Resolve]DNS=6.6.6.6
[Gateway]DNS=7.7.7.7
# next is an empty line

"
assert_kw_get "$ini_file" "Default" "DNS" "5.5.5.5" "same keyword, 'Default' section"
assert_kw_get "$ini_file" "Resolve" "DNS" "6.6.6.6" "same keyword, 'Resolve' section"

# Ok, was kinda expecting some error condition, but this is the INI-FORMAT FILE.
# If keyword does not exist, it is really a 'NULL" response thing, not an error
assert_kw_get "$ini_file" "NoSuchSection" "DNS" "" "same keyword, 'NoSuchSection' section"


# Pattern slippage around undersized keyword
ini_file="# comment line
[Default]FallbackDNS=8.8.8.8
[Resolve]DNS_Server1=9.9.9.9
[Gateway]Hidden_DNS_Master=10.10.10.10
"
assert_kw_get "$ini_file" "" "" "" "unused keyword"
assert_kw_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_kw_get "$ini_file" "Resolve" "DNS" "" "unused keyword, 'Resolve' section"
assert_kw_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"

# Pattern slippage with whitespace around undersized keyword
ini_file="# comment line
[Default]FallbackDNS=11.11.11.11
[Resolve] DNS_Server1=12.12.12.12
[Gateway]Hidden_DNS_Master=13.13.13.13
"
assert_kw_get "$ini_file" "" "" "" "unused keyword"
assert_kw_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_kw_get "$ini_file" "Resolve" "DNS" "" "unused keyword, 'Resolve' section"
assert_kw_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"

# Keyword skipping over an errored INI entry
# Pattern slippage with whitespace inside a keyword
ini_file="# comment line
[Default]FallbackDNS=14.14.14.14
[Resolve]DNS _Server1=15.15.15.15
[Gateway]Hidden_DNS_Master=16.16.16.16
"
assert_kw_get "$ini_file" "" "" "" "unused keyword"
assert_kw_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_kw_get "$ini_file" "Default" "FallbackDNS" "14.14.14.14" "standard"
assert_kw_get "$ini_file" "Resolve" "DNS" "" "incomplete but matching keyword, 'Resolve' section"
assert_kw_get "$ini_file" "Resolve" "DNS_Server1" "" "incomplete but matching keyword, 'Resolve' section, NULL answer"
assert_kw_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"

# Sectional skipping, heavily commented
ini_file="# comment line
[Default]FallbackDNS=17.17.17.17
[Resolve]DNS_Server1=18.18.18.18   # should NOT get this one
[Resolve]DNS=19.19.19.19   # should NOT this one 
[Resolve]DNS_Server2=20.20.20.20   # should get this one 
[Resolve]DNS=21.21.21.21   # should get this one
[Gateway]Hidden_DNS_Master=22.22.22.22
"
assert_kw_get "$ini_file" "" "" "" "unused keyword"
assert_kw_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_kw_get "$ini_file" "Gateway" "Hidden_DNS_Master" "22.22.22.22" "standard"
assert_kw_get "$ini_file" "Resolve" "DNS" "21.21.21.21" "keyword 2 of 2, 'Resolve' section"
assert_kw_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"

# Multiple same-sectional segments
ini_file="# comment line
[Default]FallbackDNS=21.21.21.21
[Resolve]DNS_Server1=22.22.22.22
[DifferentSection]DNS=23.23.23.23
[Resolve]DNS=24.24.24.24
[Resolve]DNS_Server2=25.25.25.25
[DifferentSection2]DNS=26.26.26.26
[Resolve]DNS=27.27.27.27
[Gateway]Hidden_DNS_Master=28.28.28.28
"
assert_kw_get "$ini_file" "" "" "" "unused keyword"
assert_kw_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_kw_get "$ini_file" "Resolve" "DNS" "27.27.27.27" "keyword 2 of 2, 'Resolve' section"
assert_kw_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"

# in-line comment recovery
ini_file="# comment line
[Default]FallbackDNS=30.30.30.30  # comment 1
[Resolve]DNS_Server1=31.31.31.31  ; comment 2
[DifferentSection]DNS=32.32.32.32  // comment 3
[Resolve]DNS=33.33.33.33  # comment 4
[Resolve]DNS_Server2=34.34.34.34  ; comment 5
[DifferentSection2]DNS_2=35.35.35.35  // comment 6
[Resolve]DNS=36.36.36.36  ; comment 7
;  comment 8
#  comment 9
//   comment 10
[Gateway]Hidden_DNS_Master=37.37.37.37  # comment 11
"
assert_kw_get "$ini_file" "" "" "" "unused keyword"
assert_kw_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_kw_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"
assert_kw_get "$ini_file" "Default" "FallbackDNS" "30.30.30.30" "standard"
assert_kw_get "$ini_file" "Resolve" "DNS_Server1" "31.31.31.31" "standard"
assert_kw_get "$ini_file" "DifferentSection" "DNS" "32.32.32.32" "standard"
assert_kw_get "$ini_file" "Resolve" "DNS_Server2" "34.34.34.34" "standard"
assert_kw_get "$ini_file" "DifferentSection2" "DNS_2" "35.35.35.35" "standard"
assert_kw_get "$ini_file" "Resolve" "DNS" "36.36.36.36" "standard"

# in-line comment recovery, value are double-quoted
ini_file="# comment line
[Default]FallbackDNS=\"40.40.40.40\"  # comment 1
[Resolve]DNS_Server1=\"41.41.41.41\"  ; comment 2
[DifferentSection]DNS=\"42.42.42.42\"  // comment 3
[Resolve]DNS=\"43.43.43.43\"  # comment 4
[Resolve]DNS_Server2=\"44.44.44.44\"  ; comment 5
[DifferentSection2]DNS_2=\"45.45.45.45\"  // comment 6
[Resolve]DNS=\"46.46.46.46\"  ; comment 7
;  comment 8
#  comment 9
//   comment 10
[Gateway]Hidden_DNS_Master=\"47.47.47.47\" # comment 11
"
assert_kw_get "$ini_file" "" "" "" "unused keyword"
assert_kw_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_kw_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"
assert_kw_get "$ini_file" "Default" "FallbackDNS" "\"40.40.40.40\"" "standard"
assert_kw_get "$ini_file" "Resolve" "DNS_Server1" "\"41.41.41.41\"" "standard"
assert_kw_get "$ini_file" "DifferentSection" "DNS" "\"42.42.42.42\"" "standard"
assert_kw_get "$ini_file" "Resolve" "DNS_Server2" "\"44.44.44.44\"" "standard"
assert_kw_get "$ini_file" "DifferentSection2" "DNS_2" "\"45.45.45.45\"" "standard"
assert_kw_get "$ini_file" "Resolve" "DNS" "\"46.46.46.46\"" "standard"
assert_kw_get "$ini_file" "Gateway" "Hidden_DNS_Master" "\"47.47.47.47\"" "standard"

# comment symbols are inside double-quotes 
# (here, double-quotes should not be treated as a inline comment)
ini_file="# comment line
[Default]FallbackDNS=\"50.50#50.50\"
[Resolve]DNS_Server1=\"51.51;51.51\"
[DifferentSection]DNS=\"52.52.52.52\"
[Resolve]DNS=\"#53.53.53.53\"
[Resolve]DNS_Server2=\";54.54.54.54\"
[DifferentSection2]DNS_2=\"//55.55.55.55\"
[Resolve]DNS=\"56.56.56.56;\"
[Gateway]Hidden_DNS_Master=\"57.57.57.57#\"
[Gateway]Hidden_DNS_Master2=\"58.58.58.58//\"
"
assert_kw_get "$ini_file" "" "" "" "unused keyword"
assert_kw_get "$ini_file" "" "DNS" "" "unused keyword, 'no-section default"
assert_kw_get "$ini_file" "NoSuchSection" "DNS" "" "unused keyword, noSuchSection"
assert_kw_get "$ini_file" "Default" "FallbackDNS" "\"50.50#50.50\"" "standard"
assert_kw_get "$ini_file" "Resolve" "DNS_Server1" "\"51.51;51.51\"" "standard"
assert_kw_get "$ini_file" "DifferentSection" "DNS" "\"52.52.52.52\"" "standard"
assert_kw_get "$ini_file" "Resolve" "DNS_Server2" "\";54.54.54.54\"" "standard"
assert_kw_get "$ini_file" "DifferentSection2" "DNS_2" "\"//55.55.55.55\"" "standard"
assert_kw_get "$ini_file" "Resolve" "DNS" "\"56.56.56.56;\"" "standard"
assert_kw_get "$ini_file" "Gateway" "Hidden_DNS_Master" "\"57.57.57.57#\"" "standard"
assert_kw_get "$ini_file" "Gateway" "Hidden_DNS_Master2" "\"58.58.58.58//\"" "standard"

# comment symbols are inside double-quotes 
# (here, single-quotes should not be treated as a inline comment)
ini_file="# comment line
[Default]FallbackDNS=\"60.60#60.60\"
[Resolve]DNS_Server1=\"61.61;61.61\"
[DifferentSection]DNS=\"62.62//62.62\"
[Resolve]DNS=\"#63.63.63.63\"
[Resolve]DNS_Server2=\";64.64.64.64\"
[DifferentSection2]DNS_2=\"//65.65.65.65\"
[Resolve]DNS=\"66.66.66.66;\"
[Gateway]Hidden_DNS_Master=\"67.67.67.67#\"
[Gateway]Hidden_DNS_Master2=\"68.68.68.68//\"
"
assert_kw_get "$ini_file" "" "" "" "no section, no keyword"
assert_kw_get "$ini_file" "" "DNS" "" "no-section, unused keyword"
assert_kw_get "$ini_file" "NoSuchSection" "DNS" "" "unused section, unused keyword"
assert_kw_get "$ini_file" "Default" "FallbackDNS" "\"60.60#60.60\"" "# inside double-quote"
assert_kw_get "$ini_file" "Resolve" "DNS_Server1" "\"61.61;61.61\"" "; inside double-quote"
assert_kw_get "$ini_file" "DifferentSection" "DNS" "\"62.62//62.62\"" "// inside double-quote"
assert_kw_get "$ini_file" "Resolve" "DNS_Server2" "\";64.64.64.64\"" "; inside LHS double-quote"
assert_kw_get "$ini_file" "DifferentSection2" "DNS_2" "\"//65.65.65.65\"" "// inside LHS double-quote"
assert_kw_get "$ini_file" "Resolve" "DNS" "\"66.66.66.66;\"" "; inside RHS double-quote"
assert_kw_get "$ini_file" "Gateway" "Hidden_DNS_Master" "\"67.67.67.67#\"" "# inside RHS double-quote"
assert_kw_get "$ini_file" "Gateway" "Hidden_DNS_Master2" "\"68.68.68.68//\"" "// inside RHS double-quote"

# comment symbols are inside AND outside of single-quotes 
ini_file="# comment line
[Default]FallbackDNS=\"70.70#70.70\"  # inline # inside double-quote
[Resolve]DNS_Server1=\"71.71;71.71\"  ; inline ; inside double-quote
[DifferentSection]DNS=\"72.72//72.72\"  // \"comment 3\" ; still an inline
[Resolve]DNS=\"#73.73.73.73\"  # inline # LHS double-quote
[Resolve]DNS_Server2=\";74.74.74.74\"  ; inline ; LHS double-quote
[DifferentSection2]DNS_2=\"//75.75.75.75\"  // inline '/' '/' LHS double-quote
[Resolve]DNS=\"76.76.76.76;\"  ; inline ; RHS double-quote
[Gateway]Hidden_DNS_Master=\"77.77.77.77#\"  # inline # RHS double-quote
[Gateway]Hidden_DNS_Master2=\"78.78.78.78//\"  // inline '/' '/' RHS double-quote
"
assert_kw_get "$ini_file" "Default" "FallbackDNS" "\"70.70#70.70\"" "# inside double-quote and outside"
assert_kw_get "$ini_file" "Resolve" "DNS_Server1" "\"71.71;71.71\"" "; inside quote and outside"

assert_kw_get "$ini_file" "Resolve" "DNS_Server2" "\";74.74.74.74\"" "; inside LHS double-quote and outside"

assert_kw_get "$ini_file" "Resolve" "DNS" "\"76.76.76.76;\"" "\"76.76.76.76;\"" "; inside RHS double-quote and outside"
assert_kw_get "$ini_file" "Gateway" "Hidden_DNS_Master" "\"77.77.77.77#\"" "\"77.77.77.77#\"" "# inside RHS double-quote and ouside"

# FAILED TEST (needs to improve 'ini_file_read' REGEX)
# Obviously that a multi-state regex for '//' is needed
assert_kw_get "$ini_file" "Gateway" "Hidden_DNS_Master2" "\"78.78.78.78//\"" "// inside RHS double-quote and outside"

assert_kw_get "$ini_file" "DifferentSection" "DNS" "\"72.72//72.72\"" "// inside double-quote and outside"
assert_kw_get "$ini_file" "DifferentSection2" "DNS_2" "\"//75.75.75.75\"" "// inside LHS double-quote and outside"
echo

echo "${BASH_SOURCE[0]}: Done."

