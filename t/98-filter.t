#!perl
use strict;
use warnings;
use FindBin::libs;
use Test::Base tests => 23;
use Ridge::Test 'Sandbox';
use HTTP::Status;

is get('/filtered')->content, 'filtered';
is get('/filtered')->content_type, 'foo/bar';
is get('/filtered.method')->content, 'filtered by filter_method()';
is get('/filtered.private_method')->content, 'filtered by _private_filter()';
is get('/filtered.class')->content, 'filtered by Sandbox::Filter::Test';
ok get('/filtered.redirect')->is_redirect;
is get("/filtered.$_")->content, 'filtered' for qw/first second third/;
is get('/filtered.assert')->code, RC_FORBIDDEN;
is get('/filtered.chain_stop')->code, RC_BAD_REQUEST;
is get('/filtered.chain_stop')->content_type, 'foo/bar';
is get('/filtered.goto_view')->content, 'viewed';
is get('/filtered.after_filtered')->content, 'AIUEO';
is get('/filtered/all')->content, 'default: filtered';
is get('/filtered/all.hello')->content, 'hello: filtered';
is get('/filtered/after.foo')->content, 'foo:default:after_filter:after_filter';

is get('/filtered')->header('X-Filtered-Except'), '1';
is get('/filtered.method')->header('X-Filtered-Except'), '1';
is get("/filtered.$_")->header('X-Filtered-Except'), '1' for qw/first second third/;
is get('/filtered.except')->header('X-Filtered-Except'), undef;
