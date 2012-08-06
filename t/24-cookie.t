#!perl
use strict;
use warnings;
use FindBin::libs;

use Ridge::Test 'Sandbox';
use Test::More tests => 17;
use HTTP::Message::PSGI;
use HTTP::Request::Common;

my $res = get('/index.cookie');
is $res->code, 200;

my @cookies = $res->header('Set-Cookie');
is scalar(@cookies), 3;
like $cookies[0], qr/^foo=bar;/;
like $cookies[0], qr/; domain=\.hatena\.ne\.jp\b/;
like $cookies[1], qr/^aaa=bbb;/;
like $cookies[1], qr/; domain=\.g\.hatena\.ne\.jp\b/;
like $cookies[2], qr/^date=hyphenated;/;
like $cookies[2], qr/; expires=\w+, \d+-\w+-\d+ /;


{
    my $req = Ridge::Request->new(GET('/')->to_psgi);
    is_deeply $req->cookies, {};
    is $req->cookie('rk'), undef;
}

{
    my $req = Ridge::Request->new(GET('/', Cookie => 'rk=0121321403423')->to_psgi);
    is_deeply $req->cookies, { rk => '0121321403423' };
    is $req->cookie('rk'), '0121321403423';
}


{
    my $req = Ridge::Request->new(GET('/', Cookie => 'rk=0121321403423; foo=bar')->to_psgi);
    is_deeply $req->cookies, { rk => '0121321403423', foo => 'bar' };
    is $req->cookie('rk'),  '0121321403423';
    is $req->cookie('foo'), 'bar';
}

{
    my $req = Ridge::Request->new(GET('/', Cookie => 'foo=bar+baz%20qux+')->to_psgi);
    is_deeply $req->cookies, { foo => 'bar baz qux ' };
    is $req->cookie('foo'), 'bar baz qux ';
}
