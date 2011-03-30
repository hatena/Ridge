package Ridge::Flash;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use Carp qw/croak/;

__PACKAGE__->mk_accessors(qw/req res/);

sub get {
    croak 'impl!';
}

sub set {
    croak 'impl!';
}

1;
