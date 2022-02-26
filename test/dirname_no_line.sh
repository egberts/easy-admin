

filespec=$1

# POSIX dirname ALWAYS adds '\n', so we must strip that off
# strip off the basename from the full filespec, then append 'x'
dirspec=$(dirname "${filespec:A}" ; echo x)

# strip off both the '\n' and 'x' from result
dirspec=${dirspec%??}

# shorter variant
# dirspec=$(dirname "$filespec" ; echo x); dirspec=${dirspec%??}

echo "$dirspec"
