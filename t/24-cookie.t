#!perl
use strict;
use warnings;
use FindBin::libs;

use Ridge::Test 'Sandbox';
use Test::More tests => 13;
use HTTP::Message::PSGI;
use HTTP::Request::Common;

my $res = get('/index.cookie');
is $res->code, 200;

my @cookies = $res->header('Set-Cookie');
is @cookies, 2;
like $cookies[0], qr/^foo=bar/;
like $cookies[0], qr/domain=\.hatena\.ne\.jp/;
like $cookies[1], qr/^aaa=bbb/;
like $cookies[1], qr/domain=\.g\.hatena\.ne\.jp/;


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

