package Sandbox::Engine::User;
use strict;
use warnings;
use Sandbox::Engine -Base;

sub default {
    my ($self, $r) = @_;
    $r->stash->param(
        Hello => 'World!',
    );
}

1;
