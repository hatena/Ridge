#!perl
use strict;
use warnings;
use FindBin::libs;
use Ridge::Test 'Sandbox';
use Test::More tests => 3;

is get('/index.utf8')->code, 200;
is get('/index.non_utf8')->code, 200;
ok get('/index.utf8')->content_length == get('/index.non_utf8')->content_length;
