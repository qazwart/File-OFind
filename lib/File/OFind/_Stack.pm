#! /usr/bin/env/ perl
package File::OFind::_Stack;

use strict;
use warnings;

sub _stack {
    my $self     = shift;
    my $list_ref = shift;

    if ( not exists $self->{LIST} ) {
        $self->{LIST} = [];
    }
    if ( defined $list_ref ) {
        $self->{STACK} = $list_ref;
    }
    return $self->{LIST};
}

sub new {
    my $class = CORE::shift;

    my $self = {};
    bless $self, $class;
    $self->_stack;
    return $self;
}

sub pop {
    my $self = CORE::shift;

    my $list_ref = $self->_stack;
    return pop @{$list_ref};
}

sub push {
    my $self = CORE::shift;
    my @list = @_;

    my $list_ref = $self->_stack;
    push @{$list_ref}, @list;
    return @list;
}

# Just Nop'd these for a while until I figure out how to get around
# the Core error message

sub shift {
    my $self = CORE::shift;

    my $list_ref = $self->_stack;
    return shift @{$list_ref};
}

sub unshift {
    my $self = CORE::shift;
    my @list = @_;

    my $list_ref = $self->_stack;
    unshift @{$list_ref}, @list;
    return @list;
}

1;

__END__

=pod

=head1 NAME

File::OFind::_Stack

=head1 SYNOPSIS

    $stack = File::OFind::_Stack->new;
    $stack->push($item);
    $stack->unshift($item);
    $item = $stack->pop;
    $item = $stack->shift;

=head1 DESCRIPTION

This is the Internal stack method used by the C<File::OFind> method. This
is distributed with C<File::OFind> and is not meant to be an independent
module.

=head1 CONSTRUCTORS

=over 10

=item new

Create a new empty stack object

=back

=head1 METHODS

=over 10

=item push

Pushes a list of items on the end of the stack.

    $stack->push(@list_of_items);

=item pop

Pops off an item at the end of the stack.

    my $item = $stack->pop;

=item unshift

Pushes a list of items at the B<beginning> of the stack.

    my $stack->unshift(@list_of_items);

=item shift

Pops off an item at the B<beginning> of the stack.

    my $item = $stack->shift;

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
