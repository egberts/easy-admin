#!/bin/bash
#
#  Turns out that using 'egrep' is better for raw user data input
#  as-is than using 'sed' and its multi-stage massaging of input data.

data="now is \ the / time [for] *ll ^men to get together and $ ..."
keyword="[for]"
echo "test (before): '$keyword'"
# put two backslashes before each of these characters: ][^$.*/
# Note that the first ']' doesn't need a backslash

keyword_sed=$(echo "$keyword" | sed 's:[]\[\^\$\.\*\/]:\\\\&:g')
echo "keyword_sed (after): '$keyword_sed'"

# We need two backslashes because the shell converts each double backslash in quotes to a single backslash
echo "$data" | sed 's/'"$keyword_sed"'//g'
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Ouch; did not cut the mustard."
else
  echo "pass."
fi

found_kw="$(echo "$data" \
	  | egrep ''"${keyword}"'\s*' )"
retsts=$?
if [ $retsts -ne 0 ]; then
  echo "Ouch; did not cut the mustard."
else
  echo "pass."
fi

