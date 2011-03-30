package Sandbox::Engine::Filtered::After;
use strict;
use warnings;
use Sandbox::Engine -Base;

after_filter ':all' => sub {
    my $r = shift;
    $r->res->content(join(':', $r->res->content, 'after_filter'));
    1;
};

sub default : Public {
    my ($self, $r) = @_;
    $r->res->content(join ':', $r->res->content, 'default');
}

sub foo : Public {
    my ($self, $r) = @_;
    $r->res->content('foo');
    $r->forward('default');
}

1;
