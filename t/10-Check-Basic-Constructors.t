#! /usr/bin/env perl -T
# 10-Check-Basic-Constructors.t

use strict;
use warnings;
use Test::More tests => 4;

# Test #1:  Whether File::OFind is installed
BEGIN { use_ok qq(File::OFind); }

# Test #2: Is this a good version of Perl?
cmp_ok $^V, '>', 5.008_008, qq(Checking Perl version > 5.8.8);

my $find;
my $bar;

sub bar {
    print "fubar!";
}

# Test #3:
subtest "Testing Basic Directory Opening" => sub {
    plan tests => 3;
    ok( File::OFind->new("."),
        qq(Testing constructor opening single directory) );
    ok( File::OFind->new(qw(. ..)),
        qq(Testing constructor opening list of directories) );
    eval { File::OFind->new("FOO"); };
    ok( $@, qq(Testing Constructor with bad directory) );
};

# Test #4:
subtest "Checking Constructor Options" => sub {
    plan tests => 3;
    $find = File::OFind->new( ".", { follow => 1, level => 3 } );
    is( $find->follow, 1, qq(Testing Follow Setting) );

    $find =
      File::OFind->new( ".", { follow => 1, level => 3, sub => \&bar, }, "..",
      );
    ok( $find->sub,      "Subroutine setting worked" );

    eval {
        $find =
          File::OFind->new( ".", {
		  follow => 1,
		  level  => 3,
		  sub    => \$bar,
	      },
	      "..",
	  );
    };
    ok( $@, qq(Invalid Function Detected) );
};
