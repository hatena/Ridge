#!perl
use strict;
use warnings;
use FindBin::libs;

use Ridge::Test 'Sandbox';
use Test::More tests => 6;
use Path::Class qw/file/;

my $html = "<p>FooBarBaz</p";

my $res = get('/not_found');
is $res->code, 404;
is $res->content_type, 'text/plain';
isnt $res->content, $html;

my $template = file('t', 'templates', '_error', '404.html');
$template->parent->mkpath;
$template->openw->print($html);

$res = get('/not_found');
is $res->code, 404;
is $res->content_type, 'text/html';
is $res->content, $html;

END {
    $template->remove if -e $template;
}


