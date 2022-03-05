
INI-format file Processing Design

For reading into bash variable, no bash array shall be used: All strings
or "list of strings".

if INI file has:

    a=1
    [Default]
     b = 1
    [Resolve]
        DNS = 1.1.1.1
    KeyWord = "KeyValue"

then normalized string array gets compacted like this:

    [Default]a=1
    [Default]b=1
    [Resolve]DNS=1.1.1.1
    [Resolve]KeyWord="KeyValue"

Section and key names cannot contain spacing characters.

Section-free and '[Default]' are one and the same.  Section-free
or 'no-section' INI file shall use '[Default]' internally
to minimize 'pull-up' logic throughout the code.

String values may optionally be enclosed in quote 
characters (""", decimal code 34). String values 
beginning or ending with spaces, or containing commas 
or semicolons, must be enclosed in quotes. Quote and 
backslash ("\", decimal code 92) characters, as well 
as binary characters (decimal ranges 0..31, 127..159) 
appearing inside strings must be encoded using the 
escape sequences described in this document.

If the same section appears more than once in the 
same file, or if the same key appears more than once 
in the same section, then the last occurrence prevails.

Still haven't figure out a way to choose the last 
keyword assignment to overwrite any prior same 
keyword's assignment.  This is something that a bash 
array would be excellent for, except that it is not 
POSIX compliant

We can use a list of strings that encountered the section name
but this means that section name must be of printable ASCII
not including '[' or ']' or '='.

To do 'last occurrence prevails', we could do :

  1.  live extract by section, narrow down, 
      live extract by keyword, get last line
      live extract its keyvalue
      (1*N filesize + 1*M selection file record, or N+M search lookup)
      (Should be fast enough for large bash processing with large systemd INI)

  2.  Build the ini_file_buffer from raw_buffer
      ini_section_buffer="$( echo "$ini_section_extract "ini_file_buffer" "$section_wanted" )"
      ini_keyword_buffer="$( echo "$ini_keyword_extract "$ini_section_buffer" "$section_wanted" | tail -n1 )"
      extract keyvalue from one-liner ini_keyword_buffer


The bash module is 'section-regex.sh' after creating so many 'section-*.sh'
parser.
