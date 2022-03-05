#!/bin/bash


line="asdf asdf asddf[asfasf]asdfasf=\"abc; def\" ; inline comment"
echo "line: '$line'"
uncommented="$(echo "$line" | sed -e 's/\s*;[^;\S]*$//')"
echo "uncommented: '$uncommented'"
expected="asdf asdf asddf[asfasf]asdfasf=\"abc; def\""
echo "expected: $expected"
if [ "$expected" = "$uncommented" ]; then
  echo "pass."
else
  echo "FAILED!"
fi
echo
echo "Done."
