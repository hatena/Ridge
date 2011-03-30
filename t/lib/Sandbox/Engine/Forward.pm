package Sandbox::Engine::Forward;
use strict;
use warnings;
use Sandbox::Engine -Base;

sub default : Public {
    my ($self, $r) = @_;
    $r->forward('hookup');
}

sub hookup {
    my ($self, $r) = @_;
    $r->forward('goal');
}

sub goal : Public {
    my ($self, $r) = @_;
    $r->res->content('GOAL');
}

sub invalid : Public {
    my ($self, $r) = @_;
    $r->forward('unko');
}

sub templating : Public {
    my ($self, $r) = @_;
    $r->forward('templating_goal');
}

sub templating_goal {
}

1;
