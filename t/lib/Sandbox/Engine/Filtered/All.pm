package Sandbox::Engine::Filtered::All;
use strict;
use warnings;
use Sandbox::Engine -Base;

before_filter ':all' => [
    sub {
        my $r = shift;
        $r->res->content($r->res->content . ' filtered');
        1;
    },
    sub { shift->res->content_type('text/plain'); 1 }
];

prepend_before_filter ':all' => [
    sub {
        my $r = shift;
        $r->res->content(($r->req->uri->action || 'default') . ':');
        1;
    }
];

sub defult : Public {}
sub hello  : Public {}

1;
