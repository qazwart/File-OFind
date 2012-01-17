#! /usr/bin/env/ perl
package File::OFind::_Stack;

use strict;
use warnings;

use constant {
    NEW     => 1,
    POP     => 2,
    PUSH    => 3,
    SHIFT   => 4,
    UNSHIFT => 5,
};

# WHAT'S THIS?
#
# In object oriented programming, the struture of your objects should be
# in a single method. In order to do this, I have a single B<private>
# _Stack method handle all operations of the stack. Then, I define
# public methods for actually manipulating the stack that call this
# private method. Thus, the internal structure of the object is stored
# in a single location.
#
# DO NOT DIRECTLY USE THIS METHOD. Use the public methods. The methods
# that are documented in the POD. The methods that don't start with an
# underscore.
#
sub _Stack {
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
    my $class = shift;

    my $self = {};
    bless $self, $class;
    $self->_Stack;
    return $self;
}

sub Pop {
    my $self = shift;

    my $list_ref = $self->_Stack;
    return pop @{$list_ref};
}

sub Push {
    my $self = shift;
    my @list = @_;

    my $list_ref = $self->_Stack;
    push @{$list_ref}, @list;
    return @list;
}

sub Shift {
    my $self = shift;

    my $list_ref = $self->_Stack;
    return shift @{$list_ref};
}

sub Unshift {
    my $self = shift;
    my @list = @_;

    my $list_ref = $self->_Stack;
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
    $stack->Push($item);
    $stack->Unshift($item);
    $item = $stack->Pop;
    $item = $stack->Shift;

=head1 DESCRIPTION

This is the Internal stack method used by the C<File::OFind> method. This
is distributed with C<File::OFind> and is not meant to be an independent
module.

=head1 CONSTRUCTOR

=over 10

=item new

Creates a new stack.

    my $stack = File::OFind::_Stack->new;

=back

=head1 METHODS

=over 10

=item Push

Pushes a list of items on the end of the stack.

    $stack->Push(@list_of_items);

=item Pop

Pops off an item at the end of the stack.

    my $item = $stack->Pop;

=item Unshift

Pushes a list of items at the B<beginning> of the stack.

    my $stack->Unshift(@list_of_items);

=item Shift

Pops off an item at the B<beginning> of the stack.

    my $item = $stack->Shift;

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
