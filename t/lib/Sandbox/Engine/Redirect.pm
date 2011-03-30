package Sandbox::Engine::Redirect;
use strict;
use warnings;
use Sandbox::Engine -Base;

sub default : Public {
    my ($self, $r) = @_;
    $r->res->redirect('/');
}

1;

