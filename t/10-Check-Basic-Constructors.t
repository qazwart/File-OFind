#! /usr/bin/env perl -T
# 10-Check-Basic-Constructors.t

use strict;
use warnings;
use Test::More tests => 5;

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
subtest "Checking dashes and case in options" => sub {
    plan tests => 2;
    $find = File::OFind->new( ".", { -Level => 3 }, );
    is( $find->Level, 3, qq(Testing option "-Level") );

    $find = File::OFind->new( ".", { "--LEVEL" => 3 }, );
    is( $find->Level, 3, qq(Testing option "--LEVEL") );
};

# Test #5:
subtest "Checking Constructor Options" => sub {
    plan tests => 4;
    $find = File::OFind->new( ".", { follow => 1, level => 3 } );
    is( $find->Follow, 1, qq(Testing Follow Setting) );

    $find =
      File::OFind->new( ".", { follow => 1, level => 3, sub => \&bar, }, "..",
      );
    ok( $find->Sub,      "Subroutine setting worked" );
    ok( $find->Function, "Testing Function alias" );

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
