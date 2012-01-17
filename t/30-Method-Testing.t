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

use Test::More tests => 23;

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

my $file_obj = $find->Next;    #Temp Directory
$file_obj = $find->Next;       #File "a.pl"

my $stat = stat $file_obj->Name;

my @method_list = qw(
  dev		ino	mode	nlink	uid	gid
  size	atime	mtime	ctime	blksize blocks);

foreach my $method (@method_list) {
    my $method_name = ucfirst $method;
    is( $file_obj->$method_name, $stat->$method,
        "Testing Method $method_name" );
}

#
# Aliases
#
is( $file_obj->Inode,         $stat->ino, "Testing Method Inode" );
is( $file_obj->Device_Number, $stat->dev, "Testing Method Device_Number" );
is( $file_obj->Number_Of_Links, $stat->nlink,
    "Testing Method Number_Of_Links" );
is( $file_obj->User_Id,    $stat->uid,     "Testing Method User_Id" );
is( $file_obj->Group_Id,   $stat->gid,     "Testing Method Group_Id" );
is( $file_obj->Block_Size, $stat->blksize, "Testing Method Block_Size" );

#
# Permissions
#

my $perms = sprintf( "%04o", $stat->mode & 07777 );
is( $file_obj->Permissions, $perms,    "Testing Method Permissions" );
is( $file_obj->Suffix,      "pl",      "Testing Method Suffix" );
is( $file_obj->Basename,    "a.pl",    "Testing Method Basename" );
is( $file_obj->Dirname,     $temp_dir, "Testing Method Dirname" );
is( $file_obj->Directory,   $temp_dir, "Testing Method Directory" );
