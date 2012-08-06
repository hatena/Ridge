package Sandbox::Engine::Hoge;
use strict;
use warnings;
use Sandbox::Engine -Base;
use Ridge::Exceptions;
use HTTP::Status qw/:constants/;

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

sub follow_method : Public {
    my ($self, $r) = @_;
    $r->follow_method;
}

sub _follow_method_get {
    my ($self, $r) = @_;
    $r->res->content('/hoge.follow_method');
}

sub no_content : Public {
    my ($self, $r) = @_;
    $r->res->code(HTTP_NO_CONTENT);
}

1;
