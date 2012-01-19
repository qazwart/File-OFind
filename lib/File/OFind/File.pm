#! /usr/bin/env perl
# File.pm

package File::OFind::File;

use strict;
use warnings;

use Cwd qw(realpath);
use File::Spec::Functions qw(:ALL);
use File::stat;

sub _new {
    my $class = shift;
    my $file  = shift;

    my $self = {};
    bless $self, $class;
    $self->name($file);
    return $self;
}

sub name {
    my $self = shift;
    my $name = shift;

    if ( defined $name ) {
        $self->{NAME} = $name;
    }
    return $self->{NAME};
}

sub wanted {
    my $self   = shift;
    my $wanted = shift;

    if ( defined $wanted ) {
        $self->{WANTED} = $wanted;
    }
    return $self->{WANTED};
}

sub native {
    my $self = shift;

    my $name = $self->name;
    my @path = splitpath($name);
    return catpath(@path);
}

sub basename {
    my $self = shift;

    my ( $volume, $path, $file ) = splitpath( $self->name );
    return $file;
}

sub dirname {
    my $self = shift;

    my ( $volume, $path, $file ) = splitpath( $self->name );
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

sub suffix {
    my $self        = shift;
    my $suffix_mark = shift;

    if ( not defined $suffix_mark ) {
        $suffix_mark = ".";
    }

    my $file = $self->name;
    ( my $suffix = $file ) =~ s/^.*\Q$suffix_mark\E//;
    return $suffix;
}

sub absolute {
    my $self = shift;

    return realpath( $self->name );
}

sub type {
    my $self = shift;

    my $file = $self->name;
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

sub dev {
    my $self = shift;

    my $stat = stat( $self->name );
    return $stat->dev;
}

sub ino {
    my $self = shift;
    my $stat = stat $self->name;

    return $stat->ino;
}

sub mode {
    my $self = shift;

    my $stat = stat $self->name;
    return $stat->mode;
}

sub permissions {
    my $self = shift;

    return sprintf "%04o", $self->mode & oct( 7777 );
}

sub nlink {
    my $self = shift;

    my $stat = stat $self->name;
    return $stat->nlink;
}

sub uid {
    my $self = shift;

    my $stat = stat $self->name;
    return $stat->uid;
}

sub gid {
    my $self = shift;

    my $stat = stat $self->name;
    return $stat->gid;
}

sub rdev {
    my $self = shift;

    my $stat = $self->name;
    return $stat->rdev;
}

sub size {
    my $self = shift;

    my $stat = stat $self->name;
    return $stat->size;
}

sub atime {
    my $self = shift;

    my $stat = stat $self->name;
    return $stat->atime;
}

sub mtime {
    my $self = shift;

    my $stat = stat $self->name;
    return $stat->mtime;
}

sub ctime {
    my $self = shift;

    my $stat = stat $self->name;
    return $stat->ctime;
}

sub blksize {
    my $self = shift;

    my $stat = stat $self->name;
    return $stat->blksize;
}

sub blocks {
    my $self = shift;

    my $stat = stat $self->name;
    return $stat->blocks;
}

1;

__END__

=pod

=head1 NAME

File::OFind::File;

=head1 SYNOPSIS

    while (my $file = $find->next) {   #$find is a member of the File::OFind class

	print "File Name: " . $file->name . "\n";
	print "File Directory: " . $file->dirname . "\n";
	print "File Basename: " . $file->basename . "\n";
	print "File Suffix: " . $file->suffix . "\n";
    }

=head1 DESCRIPTION

This is a type of object that's returned by the C<File::OFind->next>
method.

=head1 METHODS

These are the methods of the c<File::Find::File> object that gets
returned to you via the next method or that is passed to your 
subroutine via the C<< File::OFind->sub >> method.

=over 10

=item name

Full name of the file. Similar to C<$File::Find::name>.

=item native

Name of the file written in a format compatible with the current
operating system. For example, in a Windows PC, the name will have
backslashes instead of forward slashes as directory separators.

=item wanted

The File::OFind module allows you to set a reference to a subroutine
when searching for files. If that subroutine returns a null value, that
file is not included in the list of files found. However, if that
subroutine does return a value, that value is returned by the Wanted
method of the Find::OFile::File object.

=item basename

The file name without the directory information. Sort of like the Unix
C<basename> command.

=item dirname

The parent directory of the file. Similar to the Unix C<dirname>
function, but made to be more file system independent.

=item suffix

The file suffix. This is the part after the very last period or whatever
string you specify. If there is no suffix divider, a null string is
returned.

=item absolute

The absolute file name from the root directory. Normally, file names are
reletive to the current directory.

=item type

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

=item dev

Device Number of File System

=item ino

I-Node Number

=item mode

Type and Permission

=item permissions

This takes the Mode and masks out the Permissions and prints them out in
Octal. This makes your life a wee bit easier.

=item nlink

Number of Hard Links to File

=item uid

Numeric User ID

=item gid

Numeric Group ID

=item rdev

The Device Identifier (for special devices)

=item size

File size in bytes

=item atime

Last Access Time for File is Seconds since the Epoc

=item mtime

Last modification Time for File in Seconds since the Epoc

=item ctime

Last inode Change  Time for File in Seconds since the Epoc

=item blksize

Perferred Block Size for the file System's I/O

=item blocks

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
