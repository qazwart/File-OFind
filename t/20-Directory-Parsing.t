#! /usr/bin/perl -T
# 20-Directory-Parsing.t

use strict;
use warnings;
use feature qw(say);

use File::OFind;

use Cwd;
use File::Basename;
use File::Copy;
use File::Path;
use File::Spec;
use File::stat;
use File::Temp;

use Test::More tests => 9;

use constant FILE_LIST => qw(
  a/a-file		a/b/a-file		a/b/b-file
  a/b/c-file		a/b/e/a-file		a/b/e/b-file
  a/b/e/c-file		a/b/e/e-file		a/b/e/f-file
  a/b/e/g-file		a/b/e-file		a/b/f/a-file
  a/b/f/b-file		a/b/f/c-file		a/b/f/e-file
  a/b/f/f-file		a/b/f/g-file		a/b/f-file
  a/b/g/a-file		a/b/g/b-file		a/b/g/c-file
  a/b/g/e-file		a/b/g/f-file		a/b/g/g-file
  a/b/g-file		a/b-file		a/c/a-file
  a/c/b-file		a/c/c-file		a/c/e-file
  a/c/f-file		a/c/g-file		a/c/h/a-file
  a/c/h/b-file		a/c/h/c-file		a/c/h/e-file
  a/c/h/f-file		a/c/h/g-file		a/c-file
  a/d/a-file		a/d/b-file		a/d/c-file
  a/d/e-file		a/d/f-file		a/d/g-file
  a/d/i/a-file		a/d/i/b-file		a/d/i/c-file
  a/d/i/e-file		a/d/i/f-file		a/d/i/g-file
  a/d/i/j/a-file	a/d/i/j/b-file		a/d/i/j/c-file
  a/d/i/j/e-file	a/d/i/j/f-file		a/d/i/j/g-file
  a/d/i/k/a-file	a/d/i/k/b-file		a/d/i/k/c-file
  a/d/i/k/e-file	a/d/i/k/f-file		a/d/i/k/g-file
  a/d/i/l/a-file	a/d/i/l/b-file		a/d/i/l/c-file
  a/d/i/l/e-file	a/d/i/l/f-file		a/d/i/l/g-file
  a/e-file		a/f-file		a/g-file
  b/a-file		b/b-file		b/c-file
);

#
# Basic Test Setup
#

my $temp_dir;
eval { $temp_dir = File::Temp->newdir( DIR => File::Spec->curdir ); };
if ($@) {
    BAIL_OUT(qq(Cannot create temporary directory for testing));
}
pass("Temporary test root directory created: $temp_dir");

sub wanted {
    my $self = shift;

    return if not $self->Type eq "f";
    my $file_name = $self->Name;
    return $file_name;
}

#
# File list without "b" directory
#

my @a_file_list = grep { /^a\// } FILE_LIST;
my @b_file_list = grep { /^b\// } FILE_LIST;

subtest "Setting up test directory structure" => sub {
    plan tests => 2;

    my %dir_hash;

    foreach my $file (FILE_LIST) {
        my $dir = dirname $file;
        $dir_hash{$dir} = 1;
    }
    my @dir_list = keys %dir_hash;

    #
    # Create files in Temporary Directory
    #
    chdir $temp_dir or BAIL_OUT(qq(Unable to change to "$temp_dir"));
    eval { mkpath( \@dir_list ); };
    if ($@) {
        BAIL_OUT("Could not create test directory structure: $@");
    }
    pass("Created Test Directory Structure");

    #
    # Back to Current Directory
    #
    chdir File::Spec->updir;
    for my $file (FILE_LIST) {
        copy __FILE__, File::Spec->catfile( $temp_dir, $file )
          or BAIL_OUT("Could not create file tree for testing");
    }
    pass("Created file tree for testing");
};

subtest "Basic Tree Follow Test" => sub {
    plan tests => 2;

    #
    # Search from Temp Directory
    #
    chdir $temp_dir;
    my $find;
    eval { $find = File::OFind->new("a"); };
    if ($@) {
        BAIL_OUT("Could not create File::OFind object: $@");
    }
    pass("OFile::OFind object created");

    my @fetched_file_list;
    while ( my $file_obj = $find->Next ) {
        my $file_obj_name = $file_obj->Name;
        if ( -f $file_obj_name ) {
            push @fetched_file_list, $file_obj_name;
        }
    }
    is_deeply( \@a_file_list, \@fetched_file_list,
        "Fetched tree matches expected list" );

    #
    # Back to Current Directory
    #
    chdir File::Spec->updir;
};

subtest "Follow Tree using Wanted Function" => sub {
    plan tests => 2;

    #
    # Search from Temp Directory
    #
    chdir $temp_dir;
    my $find;
    eval { $find = File::OFind->new( "a", { Sub => \&wanted }, ); };
    if ($@) {
        BAIL_OUT("Could not create File::OFind object: $@");
    }
    pass("OFile::OFind object created");
    my @file_list;
    while ( my $file_obj = $find->Next ) {
        push @file_list, $file_obj->Wanted;
    }
    is_deeply( \@a_file_list, \@file_list,
        "Fetched tree matches expected list" );

    chdir File::Spec->updir;
};

subtest "Follow tree using Wanted and Next_File Method" => sub {
    plan tests => 2;

    chdir $temp_dir;
    my $find;
    eval { $find = File::OFind->new( "a", { Function => \&wanted }, ); };
    if ($@) {
        BAIL_OUT("Could not create File::OFind object: $@");
    }
    pass("OFile::OFind object created");
    my @file_list;
    while ( my $file_name = $find->Next_File ) {
        push @file_list, $file_name;
    }
    is_deeply( \@a_file_list, \@file_list,
        "Fetched tree matches expected list" );
    chdir File::Spec->updir;
};
subtest "Testing Depth First Functionality" => sub {
    plan tests => 2;

    chdir $temp_dir;
    my $find;
    eval { $find = File::OFind->new( "a", { Depth => 1 }, ); };
    if ($@) {
        BAIL_OUT("Could not create File::OFind object: $@");
    }
    pass("OFile::OFind object created");

    my $test_flag = 0;
    my $prev_file;
    while ( my $file_name = $find->Next_File ) {
        if ( -d $file_name and defined $prev_file ) {
            my $dir_name = $file_name;
            if ( dirname($prev_file) ne $dir_name ) {
                $test_flag++;
            }
        }
        $prev_file = $file_name;
    }
    is( $test_flag, 0, "Directories not depth first fetched: $test_flag" );
    chdir File::Spec->updir;
};

subtest "Level Testing" => sub {

    chdir $temp_dir;
    my $find;
    plan tests => 8;
    foreach my $level ( 0 .. 3 ) {
        eval { $find = File::OFind->new( "a", { Level => $level }, ); };
        if ($@) {
            BAIL_OUT("Could not create File::OFind object: $@");
        }
        pass("OFile::OFind object created");

        my $too_deep_count = 0;
        while ( my $file = $find->Next_File ) {
            if ( ( $level + 2 ) < scalar split( /\//, $file ) ) {
                $too_deep_count++;
            }
        }
        is( $too_deep_count, 0, "Depth Testing Level $level" );
    }
    chdir File::Spec->updir;
};

SKIP: {
    chdir $temp_dir;
    eval { symlink File::Spec->catfile( File::Spec->updir, "b" ), "a/z"; };
    skip "Symbolic Link Not Supported on OS", 2, if $@;
    subtest "Testing Follow Option" => sub {
        plan tests => 2;

        my $find;
        eval {
            $find = File::OFind->new(
                "a",
                {
                    Follow => 1,
                    Sub    => \&wanted
                },
            );
        };
        if ($@) {
            BAIL_OUT("Could not create File::OFind object: $@");
        }
        pass("OFile::OFind object created");

        foreach (@b_file_list) {
            s|b|a/z|;    #Replace "b" with link directory
        }

        my @complete_file_list = ( @a_file_list, @b_file_list );

        my @file_list;
        while ( my $file_name = $find->Next_File ) {
            push @file_list, $file_name;
        }
        is_deeply( \@complete_file_list, \@file_list,
            "Fetched tree matches expected list" );
    };

    subtest "Detecting Loop in Symbolic links" => sub {
        plan tests => 2;

        symlink File::Spec->catfile( File::Spec->updir, "a" ), "b/z";

        my $stat  = stat "a";
        my $inode = $stat->ino;

        my $find;
        eval { $find = File::OFind->new( "a", { Follow => 1 }, ); };
        if ($@) {
            BAIL_OUT("Could not create File::OFind object: $@");
        }
        pass("OFile::OFind object created");

        eval {
            my $loop_detect = 0;
            while ( my $file_obj = $find->Next ) {
                if ( $loop_detect > 3 ) {
                    last;
                }
                if ( $file_obj->Inode == $inode ) {
                    $loop_detect++;
                }
            }
        };
        if ($@) {
            pass("Symbolic Link Loop Detection Test Passed");
        }
        else {
            fail("Symbolic Link Loop Detection Test Failed");
        }
    };
    chdir File::Spec->updir;
}
