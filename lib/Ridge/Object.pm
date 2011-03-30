package Ridge::Object;
use strict;
use warnings;
use base qw/Class::Accessor::Fast Class::Data::Inheritable/;

sub new {
    my $self = bless $_[1] || {}, $_[0];
    if ($self->can('_init')) {
        $self->_init($_[1]);
    }
    return $self;
}

1;
