#!perl
use strict;
use warnings;
use FindBin::libs;
use Test::More 'no_plan';
use Ridge::Test 'Sandbox';
my $res;

$res = get('/');
is $res->header('X-Ridge-Dispatch'), 'Sandbox::Engine::Index#default';
ok $res->header('X-Runtime');

$res = get('/index');
is $res->header('X-Ridge-Dispatch'), 'Sandbox::Engine::Index#default';

$res = get('/index.hello');
is $res->header('X-Ridge-Dispatch'), 'Sandbox::Engine::Index#hello';

$res = get('/index.hello.html');
is $res->header('X-Ridge-Dispatch'), 'Sandbox::Engine::Index#hello#html';

