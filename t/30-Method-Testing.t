#! /usr/bin/perl -T
# 30-Method-Testing.t

use strict;
use warnings;

use File::OFind;

use File::Basename;
use File::Copy;
use File::Path;
use File::stat;
use File::Temp;

use Test::More tests => 16;

#
# Basic Test Setup
#

my $temp_dir;
eval { $temp_dir = File::Temp->newdir; };
if ($@) {
    BAIL_OUT(qq(Cannot create temporary directory for testing));
}

copy __FILE__, "$temp_dir/a.pl" or BAIL_OUT(qq(Cannot run Method Tests));

my $find;
eval { $find = File::OFind->new($temp_dir); };
if ($@) {
    BAIL_OUT(qq(Cannot create File::OFind object));
}

my $file_obj = $find->next;    #Temp Directory
$file_obj = $find->next;       #File "a.pl"

my $stat = stat $file_obj->name;

my @method_list = qw(
  dev		ino	mode	nlink	uid	gid
  size	atime	mtime	ctime	blksize blocks);

foreach my $method (@method_list) {
    my $method_name = $method;
    is( $file_obj->$method_name, $stat->$method,
        "Testing Method $method_name" );
}

#
# Permissions
#

my $perms = sprintf( "%04o", $stat->mode & 07777 );
is( $file_obj->permissions, $perms,    "Testing Method permissions" );
is( $file_obj->suffix,      "pl",      "Testing Method suffix" );
is( $file_obj->basename,    "a.pl",    "Testing Method basename" );
is( $file_obj->dirname,     $temp_dir, "Testing Method dirname" );
