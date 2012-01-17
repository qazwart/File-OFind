#! /usr/bin/env perl
# File.pm

package File::OFind::File;

use strict;
use warnings;

use Cwd qw(realpath);
use File::Spec::Functions qw(:ALL);
use File::stat;

sub new {
    my $class = shift;
    my $file  = shift;

    my $self = {};
    bless $self, $class;
    $self->Name($file);
    return $self;
}

sub Name {
    my $self = shift;
    my $name = shift;

    if ( defined $name ) {
        $self->{NAME} = $name;
    }
    return $self->{NAME};
}

sub File {
    my $self = shift;

    return $self->Name;
}

sub Wanted {
    my $self   = shift;
    my $wanted = shift;

    if ( defined $wanted ) {
        $self->{WANTED} = $wanted;
    }
    return $self->{WANTED};
}

sub Native {
    my $self = shift;

    my $name = $self->Name;
    my @path = splitpath($name);
    return catpath(@path);
}

sub Basename {
    my $self = shift;

    my ( $volume, $path, $file ) = splitpath( $self->Name );
    return $file;
}

sub Dirname {
    my $self = shift;

    my ( $volume, $path, $file ) = splitpath( $self->Name );
    my $dir_name;
    if ( defined $volume ) {
        $dir_name = catpath( $volume, $path, "" );
    }
    else {
        $dir_name = $path;
    }
    $dir_name =~ s|/$||;
    return $dir_name;
}

sub Dir {
    my $self = shift;

    return $self->Dirname;
}

sub Directory {
    my $self = shift;

    return $self->Dirname;
}

sub Suffix {
    my $self        = shift;
    my $suffix_mark = shift;

    if ( not defined $suffix_mark ) {
        $suffix_mark = ".";
    }

    my $file = $self->Name;
    ( my $suffix = $file ) =~ s/^.*\Q$suffix_mark\E//;
    return $suffix;
}

sub Absolute {
    my $self = shift;

    return realpath( $self->Name );
}

sub Abs {
    my $self = shift;

    return $self->Absolute;
}

sub Type {
    my $self = shift;

    my $file = $self->Name;
    if ( -l $file ) {
        return "l";
    }
    elsif ( -d $file ) {
        return "d";
    }
    elsif ( -f $file ) {
        return "f";
    }
    elsif ( -p $file ) {
        return "p";
    }
    elsif ( -S $file ) {
        return "S";
    }
    elsif ( -b $file ) {
        return "b";
    }
    elsif ( -c $file ) {
        return "c";
    }
    elsif ( -t $file ) {
        return "t";
    }
    else {
        return "X";
    }
}

sub Dev {
    my $self = shift;

    my $stat = stat( $self->Name );
    return $stat->dev;
}

sub Device_Number {
    my $self = shift;

    return $self->Dev;
}

sub Ino {
    my $self = shift;
    my $stat = stat $self->Name;

    return $stat->ino;
}

sub Inode {
    my $self = shift;

    return $self->Ino;
}

sub Mode {
    my $self = shift;

    my $stat = stat $self->File;
    return $stat->mode;
}

sub Permissions {
    my $self = shift;

    return sprintf "%04o", $self->Mode & oct( 7777 );
}

sub Nlink {
    my $self = shift;

    my $stat = stat $self->File;
    return $stat->nlink;
}

sub Number_Of_Links {
    my $self = shift;

    return $self->Nlink;
}

sub Uid {
    my $self = shift;

    my $stat = stat $self->Name;
    return $stat->uid;
}

sub User_Id {
    my $self = shift;

    return $self->Uid;
}

sub Gid {
    my $self = shift;

    my $stat = stat $self->Name;
    return $stat->gid;
}

sub Group_Id {
    my $self = shift;

    return $self->Gid;
}

sub Rdev {
    my $self = shift;

    my $stat = $self->Name;
    return $stat->rdev;
}

sub Device_Id {
    my $self = shift;

    return $self->Rdev;
}

sub Size {
    my $self = shift;

    my $stat = stat $self->Name;
    return $stat->size;
}

sub Atime {
    my $self = shift;

    my $stat = stat $self->Name;
    return $stat->atime;
}

sub Mtime {
    my $self = shift;

    my $stat = stat $self->Name;
    return $stat->mtime;
}

sub Ctime {
    my $self = shift;

    my $stat = stat $self->Name;
    return $stat->ctime;
}

sub Blksize {
    my $self = shift;

    my $stat = stat $self->Name;
    return $stat->blksize;
}

sub Block_Size {
    my $self = shift;

    return $self->Blksize;
}

sub Blocks {
    my $self = shift;

    my $stat = stat $self->Name;
    return $stat->blocks;
}

sub Number_Of_Blocks {
    my $self = shift;

    return $self->Blocks;
}

1;

__END__

=pod

=head1 NAME

File::OFind::File;

=head1 SYNOPSIS

    my $file = File::OFind::File->new($file);

    print "File Name: " . $file->Name . "\n";
    print "File Directory: " . $file->Dirname . "\n";
    print "File Basename: " . $file->Basename . "\n";
    print "File Suffix: " . $file->Suffix . "\n";

=head1 DESCRIPTION

This is the Internal stack method used by the C<File::OFind> method.
This is distributed with C<File::OFind> and is not meant to be an
independent module.

The C<File::OFind>'s C<Next> method returns a File::OFind::File object.
You can get information about this object using the methods described
below. These methods are also listed in the File::OFind POD.

=head1 Constructor

=over 10

=item new

The C<new> constructor is called by the C<File::OFind> module when it
finds a file to return. You should never call the C<new> constructor
in your program.

=back

=head1 METHODS

These are the methods of the c<File::Find::File> object that gets
returned to you via the Next method or that is passed to your 
subroutine via the Wanted method.

=over 10

=item Name, File

Full name of the file. Similar to C<$File::Find::name>.

=item Native

Name of the file written in a format compatible with the current
operating system. For example, in a Windows PC, the name will have
backslashes instead of forward slashes as directory separators.

=item Wanted

The File::OFind module allows you to set a reference to a subroutine
when searching for files. If that subroutine returns a null value, that
file is not included in the list of files found. However, if that
subroutine does return a value, that value is returned by the Wanted
method of the Find::OFile::File object.

=item Basename

The file name without the directory information. Sort of like the Unix
C<basename> command.

=item Dirname, Dir, Directory

The parent directory of the file. Similar to the Unix C<dirname>
function, but made to be more file system independent.

=item Suffix

The file suffix. This is the part after the very last period or whatever
string you specify. If there is no suffix divider, a null string is
returned.

=item Absolute, Abs

The absolute file name from the root directory. Normally, file names are
reletive to the current directory.

=item Type

The file type. This returns a single letter specifying the file type,
the valid values are:

=over 10

=item l

Symbolic link

=item d

Directory

=item f

File

=item p

Unix named pipe

=item S

Berkeley Socket

=item b

Block Special File

=item c

Character Special File

=item t

Open filehandle as a TTY

=item X

Unknown file type

=back

=item Dev, Device_Number

Device Number of File System

=item Ino, Inode

I-Node Number

=item Mode

Type and Permission

=item Permissions

This takes the Mode and masks out the Permissions and prints them out in
Octal. This makes your life a wee bit easier.

=item Nlink, Number_Of_Links

Number of Hard Links to File

=item Uid, User_Id

Numeric User ID

=item Gid, Group_Id

Numeric Group ID

=item Rdev, Device_Id

The Device Identifier (for special devices)

=item Size

File size in bytes

=item Atime

Last Access Time for File is Seconds since the Epoc

=item Mtime

Last modification Time for File in Seconds since the Epoc

=item Ctime

Last inode Change  Time for File in Seconds since the Epoc

=item Blksize, Block_Size

Perferred Block Size for the file System's I/O

=item Blocks, Number_Of_Blocks

Number of blocks allocated

=back

=head1 AUTHOR

David Weintraub, L<mailto:david@weintraub.name>

=head1 LICENCE AND COPYRIGHT

Copyright E<copy> 2012 by David Weintraub. All rights reserved. This
program is covered by the open source BMAB license.

The BMAB (Buy me a beer) license allows you to use all code for whatever
reason you want with these three caveats:

=over 4

=item 1.

If you make any modifications in the code, please consider sending them
to me, so I can put them into my code.

=item 2.

Give me attribution and credit on this program.

=item 3.

If you're in town, buy me a beer. Or, a cup of coffee which is what I'd
prefer. Or, if you're feeling really spendthrify, you can buy me lunch.
I promise to eat with my mouth closed and to use a napkin instead of my
sleeves.

=back

=cut
