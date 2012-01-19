#! /usr/bin/env perl
package File::OFind;

use 5.008008;
use strict;
use warnings;
use feature qw(say);

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
	    %param_hash = %{$param};
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
    $self->depth( $param_hash{depth} );
    $self->level( $param_hash{level} );
    $self->sub($param_hash{sub} );
    $self->follow( $param_hash{follow} );

    my @obj_list;
    foreach my $dir ( reverse @dir_list ) {
        $self->_stack->push( File::OFind::_Stack::Obj->new( $dir, 0 ) );
    }

    return $self;
}

sub depth {
    my $self  = shift;
    my $depth = shift;

    if ( defined $depth ) {
        $self->{DEPTH} = 1;
    }
    return $self->{DEPTH};
}

sub level {
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

sub follow {
    my $self   = shift;
    my $follow = shift;

    if ( defined $follow ) {
        $self->{FOLLOW} = 1;
    }
    return $self->{FOLLOW};
}

sub sub {
    my $self        = shift;
    my $subroutine  = shift;

    if ( defined $subroutine ) {
	if ( not ref $subroutine eq "CODE" ) {
	    croak qq(Function parameter must be a reference to a sub.);
	}
	$self->{FUNCTION} = $subroutine;
    }
    return $self->{FUNCTION};
}

sub next_file {
    my $self = shift;
    if ( my $file_obj = $self->next ) {
        return $file_obj->name;
    }
    else {
        return;
    }
}

sub next {
    my $self = shift;

    for ( ; ; ) {
        my $stack_obj         = $self->_stack->pop or return;
        my $level             = $stack_obj->level;
        my $file              = $stack_obj->file;
        my $already_processed = $stack_obj->already_processed;

        #
        # Detect on directory link if you've seen this before
        #
        if ( -d $file and $self->follow ) {
            if ( my $prev_file = $self->_already_visited($file) ) {
                croak
                  qq(ERROR: Symlink Loop detected on "$file" and "$prev_file");
            }
        }

        #
        # If "file" is a directory, read contents and push them in stack
        #
        if ( -d $file and not $self->_too_deep($level) ) {
            if ( $self->follow or not -l $file ) {
                $self->_push_dir_into_stack($stack_obj);
            }
            if ( not $already_processed and $self->depth ) {
                next;
            }
        }
        my $file_obj = File::OFind::File->_new($file);
        if ( my $function = $self->sub ) {
            if ( my $value = &{$function}($file_obj) ) {
                $file_obj->wanted($value);
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
sub _too_deep {
    my $self  = shift;
    my $level = shift;

    return 0 if not defined $self->level;
    if ( $self->level < $level ) {
        return 1;    #Too Deep
    }
    else {
        return 0;
    }
}

sub _push_dir_into_stack {
    my $self      = shift;
    my $stack_obj = shift;

    my $dir   = $stack_obj->file;
    my $level = $stack_obj->level;

    #
    # If the contents have already been pushed into the directory,
    # don't push them back in.
    #

    if ( $stack_obj->already_processed ) {
        return;
    }

    #
    # Depth First Search: We need to put the directory on the stack,
    # before we put it's contents. We want to mark that we've already
    # dumped the contents of the directory, so we know not to do this
    # again, and just print the directory.
    #
    if ( $self->depth ) {    #Depth First Search: Put dir back on stack
        $stack_obj->already_processed(1);

        #
        # Put directory back on stack before its contents
        #
        $self->_stack->push($stack_obj);
    }
    my $dir_fh;
    opendir $dir_fh, $dir
      or croak qq(Can't open directory "$dir" for reading);
    my @dir_stack = File::Spec->no_upwards( readdir $dir_fh );
    close $dir_fh;

    foreach my $file ( reverse @dir_stack ) {
        $self->_stack->push(
            File::OFind::_Stack::Obj->new( "$dir/$file", $level + 1 ) );
    }

    return;
}

sub _prev_dir {
    my $self = shift;
    my $file = shift;

    if ( defined $file ) {
        $self->{PREV_DIR} = dirname $file;
    }
    return $self->{PREV_DIR};
}

sub _stack {
    my $self  = shift;
    my $class = ref $self;

    if ( not defined $self->{STACK} ) {
        $self->{STACK} = File::OFind::_Stack->new;
    }
    return $self->{STACK};
}

sub _already_visited {
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
	print "File Name: " . $file_obj->name . "\n";
	print "File Directory: " . $file_obj->dirname . "\n";
	print "File Basename: " . $file_obj->basename . "\n";
	print "File Suffix: " . $file_obj->suffix . "\n";
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

=over 10

=item level

The number of levels to go deep when searching for files. This is good
when you're searching a large and deep directory tree, but the files you
want are in the top few layers of that tree. A level of C<0> means you
are only looking at the files and directories directly under the
directories you specified. A level of C<1> means you're going into the
sub-directories immediately under the directories you specified, etc.

=item follow

Whether or not you want to follow symbolic directory links. Default is not
to follow links. Set this to a true value to follow links.

=item depth

This creates a depth first search where the files are returned before
their directories. Normally the directories are retrieved first, then
their contents

=item sub

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

	if ($self->type eq "d") {
	    return;
	}
	else {
	    return uc $self->name;     #Returns name in uppercase
	}
    }

In the above example, you can use the return value of the function via
the Wanted method:

    while ($file = $find->next) {
	print "File's Name: " . $file->name . "\n";   #Same as before
	print "File's Name: " . $file->wanted . "\n"; #Uppercase name
    }

=back

=head1 METHODS

=over 10

=item next

Fetch the next C<File::OFind::File> object. You can use the various
methods on these objects as described in C<perldoc File::OFind::File>.

=item next_file

Used like the L<Next> method, but only returns the file's name as
a text string. You lose the ability to use the various
<File::OFind::File> methods, but if you're just interested in the
name of the file, this can save you a set or two in your loop.

=item sub

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
