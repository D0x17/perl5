#!./perl

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 51;

$a = "HELLO.* world";
$b = "hello.* WORLD";

is("\Q$a\E."      , "HELLO\\.\\*\\ world.", '\Q\E HELLO.* world');
is("\u$a"         , "HELLO\.\* world",      '\u');
is("\l$a"         , "hELLO\.\* world",      '\l');
is("\U$a"         , "HELLO\.\* WORLD",      '\U');
is("\L$a"         , "hello\.\* world",      '\L');

is(quotemeta($a)  , "HELLO\\.\\*\\ world",  'quotemeta');
is(ucfirst($a)    , "HELLO\.\* world",      'ucfirst');
is(lcfirst($a)    , "hELLO\.\* world",      'lcfirst');
is(uc($a)         , "HELLO\.\* WORLD",      'uc');
is(lc($a)         , "hello\.\* world",      'lc');

is("\Q$b\E."      , "hello\\.\\*\\ WORLD.", '\Q\E hello.* WORLD');
is("\u$b"         , "Hello\.\* WORLD",      '\u');
is("\l$b"         , "hello\.\* WORLD",      '\l');
is("\U$b"         , "HELLO\.\* WORLD",      '\U');
is("\L$b"         , "hello\.\* world",      '\L');

is(quotemeta($b)  , "hello\\.\\*\\ WORLD",  'quotemeta');
is(ucfirst($b)    , "Hello\.\* WORLD",      'ucfirst');
is(lcfirst($b)    , "hello\.\* WORLD",      'lcfirst');
is(uc($b)         , "HELLO\.\* WORLD",      'uc');
is(lc($b)         , "hello\.\* world",      'lc');

# \x{100} is LATIN CAPITAL LETTER A WITH MACRON; its bijective lowercase is
# \x{101}, LATIN SMALL LETTER A WITH MACRON.

$a = "\x{100}\x{101}Aa";
$b = "\x{101}\x{100}aA";

is("\Q$a\E."      , "\x{100}\x{101}Aa.", '\Q\E \x{100}\x{101}Aa');
is("\u$a"         , "\x{100}\x{101}Aa",  '\u');
is("\l$a"         , "\x{101}\x{101}Aa",  '\l');
is("\U$a"         , "\x{100}\x{100}AA",  '\U');
is("\L$a"         , "\x{101}\x{101}aa",  '\L');

is(quotemeta($a)  , "\x{100}\x{101}Aa",  'quotemeta');
is(ucfirst($a)    , "\x{100}\x{101}Aa",  'ucfirst');
is(lcfirst($a)    , "\x{101}\x{101}Aa",  'lcfirst');
is(uc($a)         , "\x{100}\x{100}AA",  'uc');
is(lc($a)         , "\x{101}\x{101}aa",  'lc');

is("\Q$b\E."      , "\x{101}\x{100}aA.", '\Q\E \x{101}\x{100}aA');
is("\u$b"         , "\x{100}\x{100}aA",  '\u');
is("\l$b"         , "\x{101}\x{100}aA",  '\l');
is("\U$b"         , "\x{100}\x{100}AA",  '\U');
is("\L$b"         , "\x{101}\x{101}aa",  '\L');

is(quotemeta($b)  , "\x{101}\x{100}aA",  'quotemeta');
is(ucfirst($b)    , "\x{100}\x{100}aA",  'ucfirst');
is(lcfirst($b)    , "\x{101}\x{100}aA",  'lcfirst');
is(uc($b)         , "\x{100}\x{100}AA",  'uc');
is(lc($b)         , "\x{101}\x{101}aa",  'lc');

# \x{DF} is LATIN SMALL LETTER SHARP S, its uppercase is SS or \x{53}\x{53};
# \x{149} is LATIN SMALL LETTER N PRECEDED BY APOSTROPHE, its uppercase is
# \x{2BC}\x{E4} or MODIFIER LETTER APOSTROPHE and N.

# In EBCDIC \x{DF} is LATIN SMALL LETTER Y WITH DIAERESIS,
# and it's uppercase is \x{178}, LATIN CAPITAL LETTER Y WITH DIAERESIS.

if (ord("A") == 193) { # EBCDIC
    is("\U\x{DF}aB\x{149}cD" , "\x{178}AB\x{2BC}NCD",
       "multicharacter uppercase");
} elsif (ord("A") == 65) {
    is("\U\x{DF}aB\x{149}cD" , "SSAB\x{2BC}NCD",
       "multicharacter uppercase");
} else {
    fail("what is your encoding?");
}

# The \x{DF} is its own lowercase, ditto for \x{149}.
# There are no single character -> multiple characters lowercase mappings.

if (ord("A") == 193) { # EBCDIC
    is("\LaB\x{149}cD" , "ab\x{149}cd",
       "multicharacter lowercase");
} elsif (ord("A") == 65) {
    is("\L\x{DF}aB\x{149}cD" , "\x{DF}ab\x{149}cd",
       "multicharacter lowercase");
} else {
    fail("what is your encoding?");
}

# titlecase is used for \u / ucfirst.

# \x{587} is ARMENIAN SMALL LIGATURE ECH YIWN and its titlecase is
# \x{535}\x{582} ARMENIAN CAPITAL LETTER ECH + ARMENIAN SMALL LETTER YIWN
# while its lowercase is 
# \x{587} itself
# and its uppercase is
# \x{535}\x{552} ARMENIAN CAPITAL LETTER ECH + ARMENIAN CAPITAL LETTER YIWN

$a = "\x{587}";

is("\L\x{587}" , "\x{587}",        "ligature lowercase");
is("\u\x{587}" , "\x{535}\x{582}", "ligature titlecase");
is("\U\x{587}" , "\x{535}\x{552}", "ligature uppercase");

# mktables had problems where many-to-one case mappings didn't work right.
# The lib/unifold.t should give the fourth folding, "casefolding", a good
# workout.

is(lc("\x{1C4}") , "\x{1C6}",      "U+01C4 lc is U+01C6");
is(lc("\x{1C5}") , "\x{1C6}",      "U+01C5 lc is U+01C6, too");

is(ucfirst("\x{3C2}") , "\x{3A3}", "U+03C2 ucfirst is U+03A3");
is(ucfirst("\x{3C3}") , "\x{3A3}", "U+03C3 ucfirst is U+03A3, too");

is(uc("\x{1C5}") , "\x{1C4}",      "U+01C5 uc is U+01C4");
is(uc("\x{1C6}") , "\x{1C4}",      "U+01C6 uc is U+01C4, too");

