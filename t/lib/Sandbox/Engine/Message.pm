package Sandbox::Engine::Message;
use strict;
use warnings;
use Sandbox::Engine -Base;

sub default : Public {
    my ($self, $r) = @_;
    return $r->forward_to_message(test => 'DEFAULT', { foo => 'bar' });
}

sub error : Public {
    my ($self, $r) = @_;
    return $r->forward_to_message(error => 'ERROR', { bar => 'baz' });
}

1;
