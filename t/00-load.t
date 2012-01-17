#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('File::OFind') || print "Bail out!\n";
}

diag("Testing File::OFind $File::OFind::VERSION, Perl $], $^X");
