#



Use this solution with GNU sed:

sed ':a;N;$!ba;s/\n/ /g' file

This will read the whole file in a loop (':a;N;$!ba), then replaces the newline(s) with a space (s/\n/ /g). Additional substitutions can be simply appended if needed.

Explanation:

    sed starts by reading the first line excluding the newline into the pattern space.
    Create a label via :a.
    Append a newline and next line to the pattern space via N.
    If we are before the last line, branch to the created label $!ba ($! means not to do it on the last line. This is necessary to avoid executing N again, which would terminate the script if there is no more input!).
    Finally the substitution replaces every newline with a space on the pattern space (which is the whole file).

Here is cross-platform compatible syntax which works with BSD and OS X's sed (as per @Benjie comment):

sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' file

