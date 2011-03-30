#!perl
use strict;
use warnings;
use FindBin::libs;
use Socket;

use Ridge::Test 'Sandbox';
use Test::More tests => 8;

is get('/')->code, 200;
is get('/index.error')->code, 500;
is post('/')->code, 200;

my $res = get('/');

$res->status_code_is(200);
$res->header_is('Content-Type' => 'text/html; charset=utf-8');
$res->body_like(qr/img/);
$res->header_like('Content-Type' => qr/text/);

# Ridge::Test->host('foobar.bazbaz');
# is get('/')->code, 500;

is get('/')->code, 200;

