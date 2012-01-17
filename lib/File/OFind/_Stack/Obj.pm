#! /usr/bin/env perl
package File::OFind::_Stack::Obj;

use strict;
use warnings;

sub new {
    my $class                  = shift;
    my $file                   = shift;
    my $level                  = shift;
    my $already_processed_flag = shift;

    my $self = {};
    bless $self, $class;
    $self->Level($level);
    $self->File($file);
    $self->Already_Processed($already_processed_flag);

    return $self;
}

sub Level {
    my $self  = shift;
    my $level = shift;

    if ( defined $level ) {
        if ( $level == -1 ) {
            delete $self->{LEVEL};
        }
        else {
            $self->{LEVEL} = $level;
        }
    }
    return $self->{LEVEL};
}

sub File {
    my $self = shift;
    my $file = shift;

    if ( defined $file ) {
        $self->{FILE} = $file;
    }
    return $self->{FILE};
}

sub Already_Processed {
    my $self = shift;
    my $flag = shift;

    if ( defined $flag ) {
        if ( $flag == 0 ) {
            $self->{PROCESSED_FLAG} = undef;
        }
        else {
            $self->{PROCESSED_FLAG} = 1;
        }
    }
    return $self->{PROCESSED_FLAG};
}
1;

__END__

=pod

=head1 NAME

File::OFind::_Stack::Obj

=head1 SYNOPSIS

    $stack_obj = File::OFind::_Stack::Obj($file, $level);

    my $file = $stack_obj->File;
    my $level = $stack_obj->Level;

=head1 DESCRIPTION

This is the Internal stack method used by the C<File::OFind> method. This
is distributed with C<File::OFind> and is not meant to be an independent
module.

=head1 CONSTRUCTOR

=over 10

=item new

Creates a new stack object.

    my $stack = File::OFind::_Stack::Obj->new;

May take one to three arguments: A file/directory  name, a level which
must be either undefined or a positive integer, or C<0>, and a flag
which says whether the directory was previously processed.

The previously processed flag is for depth-first searches. It tells the
program whether the directory contents need to be dumped into the stack,
or whether this was already done and the directory should be returned.

    my $stack = File::OFind::_Stack::Obj->new($file);
    my $stack = File::OFind::_Stack::Obj->new($file, $level);
    my $stack = File::OFind::_Stack::Obj->new($file, $level, $flag);

=back

=head1 METHODS

=over 10

=item File

Sets or gets the name of the file:

    $stack->File($file);
    my $file = $stack->File;

=item Level

Sets of gets the level for that file. Must be an integer 0 or greater.

    $stack->Level(2);
    my $level = $stack->Level;

=item Already_Processed

Sets or gets whether or not the directory has had its contents already
dumped into the stack. This is used for depth first searches where the
directory must be printed B<after> its contents. When a directory is
first read, its contents are dumped on the stack. However, in a depth
first search, the directory is returned to the stack before the
contents. Thus, the contents are printed before the directory.

In order to know that you've already dumped the directory contents out,
you need a flag to mark directories that have been processed.


    $stack->Already_Processed(1);
    my $flag = $stack->Already_Processed;

=back

=head1 AUTHOR

David Weintraub L<mailto:david@weintraub.name>

=head1 LICENSE AND COPYRIGHT

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
