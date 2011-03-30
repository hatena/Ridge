package Ridge::Response::Apache2;
use strict;
use warnings;
use base qw/Ridge::Response/;
use Apache2::Cookie;

sub cookie {
    my $self = shift;
    $self->add_cookie(Apache2::Cookie->new($self->request->r, @_));
}

1;
