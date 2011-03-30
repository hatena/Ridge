package Ridge::Plugin::Hello;
use strict;
use warnings;
use base qw/Ridge::Plugin/;

sub hello : Method  {
    my ($self, $r, @args) = @_;
    return 'Hello';
}

sub bye : Method {
    my ($self, $r, @args) = @_;
    $self->{message} = 'Good ';
}

sub hello_config : Method {
    my ($self, $r, @args) = @_;
    $self->config;
}

1;
