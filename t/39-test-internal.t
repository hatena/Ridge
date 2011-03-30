#!perl
use strict;
use warnings;
use FindBin::libs;

use Ridge::Test::Internal 'Sandbox';
use Test::More tests => 10;

GET '/' => sub {
    is $_->res->code, 200;
    is $_->res->header('Content-Type'), 'text/html; charset=utf-8';
};
GET '/hoge.get_denied' => sub {
    is $_->res->code, 405;
};
POST '/hoge.get_denied' => sub {
    is $_->res->code, 404;
};
GET '/', X_Ridge_Test => 'Internal' => sub {
    is $_->req->get_header('X-Ridge-Test'), 'Internal';
};
TODO: {
    todo_skip 'アプリケーション内の die() はどうしたものか', 1;
    GET '/index.error' => sub {
        is $_->res->code, 500;
    };
}

foreach my $method (qw(GET POST PUT HEAD)) {
    __PACKAGE__->can($method)->('/' => sub {
        is $_->req->request_method, $method;
    });
}
