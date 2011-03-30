#!perl
use strict;
use warnings;
use FindBin::libs;
use Test::More 'no_plan';
use Ridge::Test 'Sandbox';

my $res = get('/message');
ok $res->is_success;
is $res->content_type, 'text/plain';
is $res->content, 'DEFAULT';

$res = get('/message.error');
ok $res->is_success;
is $res->content_type, 'text/html';
like $res->content, qr/^<html>.*<\/html>$/isx;
like $res->content, qr/<h1>ERROR<\/h1>/isx;
