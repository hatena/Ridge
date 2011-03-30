package Ridge::Flash::Cookie;
use strict;
use warnings;
use base qw/Ridge::Flash Class::Data::Inheritable/;
use Carp qw/croak/;

__PACKAGE__->mk_classdata(max_length => 255);

sub get {
    my ($self, $key) = @_;
    $key or croak('no flash key');

    my $value = $self->req->cookie($key);
    if (defined $value) {
        $self->res->cookie(
            -expires => '-1M',
            -path    => '/',
            -value   => '',
            -name    => $key,
        );
    }
    return $value;
}

sub set {
    my ($self, $key, $value) = @_;
    $key or croak('no flash key');
    defined $value  or croak('no flash value');

    return $self->res->cookie(
        -path    => '/',
        -value   => substr($value, 0 , ref($self)->max_length),
        -name    => $key,
    );
}

1;
