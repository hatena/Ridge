package Sandbox::Engine::Hoge;
use strict;
use warnings;
use Sandbox::Engine -Base;
use Ridge::Exceptions;

sub default : Public {
    my ($self, $r) = @_;
    $r->res->content('hoge');
}

sub get_denied : Public {
    my ($self, $r) = @_;
    $r->follow_method;
}

sub _get_denied_post {
}

1;
