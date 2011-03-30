#!perl
use strict;
use warnings;

use Test::More qw/no_plan/;
use Encode qw/is_utf8/;

use HTTP::Request::Common;
use HTTP::Message::PSGI;
use Ridge::Request;

{
    my $req = Ridge::Request->new(
        (POST '/', [
        title => "はてな",
        body  => 'Hello, World!!',
        ])->to_psgi
    );
    $req->charset('utf-8');

    ok $req->param('title');
    ok is_utf8 $req->param('title');

    ok $req->param('body');
    ok is_utf8 $req->param('body');

    $req->charset('Shift-JIS');

    ok $req->param('title');
    ok ! is_utf8 $req->param('title');

    ok $req->param('body');
    ok ! is_utf8 $req->param('body');

    ok not $req->param('foo');
    ok not is_utf8 $req->param('foo');
}

{
    my $req = Ridge::Request->new(
        (GET '/foo/bar/%3Faaa?foo=bar')->to_psgi
    );
    $req->charset('utf-8');

    is $req->param('foo'), 'bar';
    is $req->uri->path, '/foo/bar/%3Faaa';
}
