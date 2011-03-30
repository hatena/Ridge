#!perl
use strict;
use warnings;
use FindBin::libs;
use Test::More 'no_plan';
use Ridge::Test 'Sandbox';

my $res = get('/forward');
ok $res->is_success;
is $res->content, 'GOAL';

$res = get('/forward.invalid');
ok $res->is_error;

$res = get('/forward.templating');
ok $res->is_success;
like $res->content, qr/^FORWARD OK/;
