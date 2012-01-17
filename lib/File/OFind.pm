#! /usr/bin/env perl
package File::OFind;

use 5.008008;
use strict;
use warnings;

use File::Basename;
use File::stat;
use Carp;

use File::OFind::File;
use File::OFind::_Stack;
use File::OFind::_Stack::Obj;

our $VERSION = '1.00';

sub new {
    my $class = shift;

    #
    # Parse Options and Directories
    #
    my @dir_list;
    my %param_hash;
    foreach my $param (@_) {
        if ( ref $param eq "HASH" ) {
            foreach my $key ( keys %{$param} ) {
                ( my $option = $key ) =~
                  s/^-+//;    #Remove leading dashes from key
                $option = lc $option;
                if ( $option =~ /^(function|sub)$/i ) {
                    $param_hash{function} = $param->{$key};
                }
                else {
                    $param_hash{$option} = $param->{$key};
                }
            }
        }
        elsif ( -d $param ) {
            push @dir_list, $param;
        }
        else {
            croak qq(Directory "$param" does not exist);
        }
    }
    if ( not @dir_list ) {
        croak qq(No directories passed to "$class");
    }

    #
    # Create File::OFind Object and Initialize Stack.
    #
    my $self = {};
    bless $self, $class;
    $self->Depth( $param_hash{depth} );
    $self->Level( $param_hash{level} );
    $self->Function( $param_hash{function} );
    $self->Follow( $param_hash{follow} );

    my @obj_list;
    foreach my $dir ( reverse @dir_list ) {
        $self->_Stack->Push( File::OFind::_Stack::Obj->new( $dir, 0 ) );
    }

    return $self;
}

sub Depth {
    my $self  = shift;
    my $depth = shift;

    if ( defined $depth ) {
        $self->{DEPTH} = 1;
    }
    return $self->{DEPTH};
}

sub Level {
    my $self  = shift;
    my $level = shift;

    if ( defined $level ) {
        if ( not $level =~ /^\d+/ ) {
            croak qq(Level parameter must be a positive integer or zero);
        }
        $self->{LEVEL} = $level;
    }
    $self->{LEVEL};
}

sub Function {
    my $self     = shift;
    my $function = shift;

    if ( defined $function ) {
        if ( not ref $function eq "CODE" ) {
            croak qq(Function parameter must be a reference to a sub.);
        }
        $self->{FUNCTION} = $function;
    }
    return $self->{FUNCTION};
}

sub Follow {
    my $self   = shift;
    my $follow = shift;

    if ( defined $follow ) {
        $self->{FOLLOW} = 1;
    }
    return $self->{FOLLOW};
}

sub Sub {
    my $self     = shift;
    my $function = shift;

    return $self->Function($function);
}

sub Next_File {
    my $self = shift;
    if ( my $file_obj = $self->Next ) {
        return $file_obj->Name;
    }
    else {
        return;
    }
}

sub Next {
    my $self = shift;

    for ( ; ; ) {
        my $stack_obj         = $self->_Stack->Pop or return;
        my $level             = $stack_obj->Level;
        my $file              = $stack_obj->File;
        my $already_processed = $stack_obj->Already_Processed;

        #
        # Detect on directory link if you've seen this before
        #
        if ( -d $file and $self->Follow ) {
            if ( my $prev_file = $self->_Already_Visited($file) ) {
                croak
                  qq(ERROR: Symlink Loop detected on "$file" and "$prev_file");
            }
        }

        #
        # If "file" is a directory, read contents and push them in stack
        #
        if ( -d $file and not $self->_Too_Deep($level) ) {
            if ( $self->Follow or not -l $file ) {
                $self->_Push_Dir_Into_Stack($stack_obj);
            }
            if ( not $already_processed and $self->Depth ) {
                next;
            }
        }
        my $file_obj = File::OFind::File->new($file);
        if ( my $function = $self->Function ) {
            if ( my $value = &{$function}($file_obj) ) {
                $file_obj->Wanted($value);
                return $file_obj;
            }
        }
        else {
            return $file_obj;
        }
    }
}

#
# Check whether the directory is deeper in the directory tree than the
# maximum level that was set
#
sub _Too_Deep {
    my $self  = shift;
    my $level = shift;

    return 0 if not defined $self->Level;
    if ( $self->Level < $level ) {
        return 1;    #Too Deep
    }
    else {
        return 0;
    }
}

sub _Push_Dir_Into_Stack {
    my $self      = shift;
    my $stack_obj = shift;

    my $dir   = $stack_obj->File;
    my $level = $stack_obj->Level;

    #
    # If the contents have already been pushed into the directory,
    # don't push them back in.
    #

    if ( $stack_obj->Already_Processed ) {
        return;
    }

    #
    # Depth First Search: We need to put the directory on the stack,
    # before we put it's contents. We want to mark that we've already
    # dumped the contents of the directory, so we know not to do this
    # again, and just print the directory.
    #
    if ( $self->Depth ) {    #Depth First Search: Put dir back on stack
        $stack_obj->Already_Processed(1);

        #
        # Put directory back on stack before its contents
        #
        $self->_Stack->Push($stack_obj);
    }
    my $dir_fh;
    opendir $dir_fh, $dir
      or croak qq(Can't open directory "$dir" for reading);
    my @dir_stack = File::Spec->no_upwards( readdir $dir_fh );
    close $dir_fh;

    foreach my $file ( reverse @dir_stack ) {
        $self->_Stack->Push(
            File::OFind::_Stack::Obj->new( "$dir/$file", $level + 1 ) );
    }

    return;
}

sub _Prev_Dir {
    my $self = shift;
    my $file = shift;

    if ( defined $file ) {
        $self->{PREV_DIR} = dirname $file;
    }
    return $self->{PREV_DIR};
}

sub _Stack {
    my $self  = shift;
    my $class = ref $self;

    if ( not defined $self->{STACK} ) {
        $self->{STACK} = File::OFind::_Stack->new;
    }
    return $self->{STACK};
}

sub _Already_Visited {
    my $self = shift;
    my $file = shift;

    if ( not exists $self->{VISITED} ) {
        $self->{VISITED} = {};
    }
    my $stat = stat $file;
    my $key  = $stat->ino . "|" . $stat->dev;
    if ( exists $self->{VISITED}->{$key} ) {
        return $self->{VISITED}->{$key};
    }
    else {
        $self->{VISITED}->{$key} = $file;
        return;
    }
}

1;

__END__

=pod

=head1 NAME

File::OFind - An object oriented replacement for File::Find

=head1 VERSION

1.00

=head1 SYNOPSIS

    use File::OFind;

    my $find = File::OFind->new ( @dir_list );

    while (my $file_obj = Next) {
	print "File Name: " . $file_obj->Name . "\n";
	print "File Directory: " . $file_obj->Dirname . "\n";
	print "File Basename: " . $file_obj->Basename . "\n";
	print "File Suffix: " . $file_obj->Suffix . "\n";
    }

=head1 DESCRIPTION

File::OFind is an object oriented replacement for L<File::Find>.
C<File::OFind> was designed to be easy to use. Just pass it a list of
directories to search, and it'll act just like the Unix F<find> command.
This module uses an iterator, so that fetching each file can take place
inside your main code and not in a subroutine.

At the same time, this module allows you to set a wide array of options,
and provides a wide array of methods for fetching particular aspects of
a file.

=head1 CONSTRUCTOR

=over 10

=item new

This is used to build a new C<File::OFind> object. This object tracks
the directories you want to delve through and options. The call is
fairly straight forward:

    my $find_obj = File::OFind->new( @dir_list );

Options are listed inside an anonymous hash:

    my $file_obj = File::OFind->new(
			@dir_list,
			{
			    Option => Value,
			    Option => Value,
			},
		    );

The Next method returns a File::OFind::File object. You can use this
object to fetch many different aspects of the file.

=back

=head2 OPTIONS

The parmeters to File::OFind include a list of directories, and an
anonymous hash that contains the various options. Directory names may be
specified as a list before and after the anonymous hash. The following
are equivelent:

    File::OFind->new(@dirs, {--level => 3});
    File::OFind->new(@dirs, {Level => 3});
    File::OFind->new({-level => 3}, @dirs);


=over 10

=item Level

The number of levels to go deep when searching for files. This is good
when you're searching a large and deep directory tree, but the files you
want are in the top few layers of that tree. A level of C<0> means you
are only looking at the files and directories directly under the
directories you specified. A level of C<1> means you're going into the
sub-directories immediately under the directories you specified, etc.

=item Follow

Whether or not you want to follow symbolic directory links. Default is not
to follow links. Set this to a true value to follow links.

=item Depth

This creates a depth first search where the files are returned before
their directories. Normally the directories are retrieved first, then
their contents

=item Function, Wanted, Sub

This is a subroutine you can use to check the file to see whether or not
you want to fetch it. The File::OFind::File object is passed to this
subroutine, so it's available for you to use.

If this subroutine return a undefined value, a null string, or a "0", the
file is not fetched by the Next method and the next one will be tested.
If this subroutine returns what would be considered a I<true> value,
that value is available via the Wanted method of the File::OFind::File
object.

Below is a sample function that skips over directories:

    sub wanted {
	my $self = shift;

	if ($self->Type eq "d") {
	    return;
	}
	else {
	    return uc $self->Name;     #Returns name in uppercase
	}
    }

In the above example, you can use the return value of the function via
the Wanted method:

    while ($file = $find->Next) {
	print "File's Name: " . $file->Name . "\n";   #Same as before
	print "File's Name: " . $file->Wanted . "\n"; #Uppercase name
    }

=back

=head1 METHODS

=over 10

=item Next

Fetch the next C<File::OFind::File> object. You can use the various
methods on these objects as described in C<perldoc File::OFind::File>.

=item Next_File

Used like the L<Next> method, but only returns the file's name as
a text string. You lose the ability to use the various
<File::OFind::File> methods, but if you're just interested in the
name of the file, this can save you a set or two in your loop.

=item Sub, Function

Normally, you set this when you create the object. However, is it
possible to change the wanted subroutine in the middle of fetching the
directory tree.

=back 

=head1 AUTHOR

David Weintraub, L<mailto:david@@weintraub.name>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-ofind at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-OFind>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::OFind

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-OFind>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-OFind>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-OFind>

=item * Search CPAN

L<http://search.cpan.org/dist/File-OFind/>

=back

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
