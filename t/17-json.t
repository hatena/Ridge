#!perl
use strict;
use warnings;
use FindBin::libs;
use Ridge::Test 'Sandbox';
use Test::More 'no_plan';
use JSON::Syck;
use Encode;
use Encode::JavaScript::UCS;
use utf8;

my $res = get('/index.json');
is $res->code, 200;
is_deeply( [ $res->content_type ], [ 'application/json', 'charset=utf-8' ]);
my $data = JSON::Syck::Load($res->content);
ok ref $data;
is $data->{hello}, encode('JavaScript-UCS', '世界');

{
    my $res = get('/hello.json');
    is $res->code, 404;
}

$res = get('/index.json?callback=hello');
is $res->code, 200;
like $res->content, qr/^hello\(.*?\);$/;
is_deeply( [$res->content_type ], [ 'text/javascript', 'charset=utf-8' ]);

$res = get('/index.js_test.json');
is $res->code, 200;
is_deeply( [ $res->content_type ], [ 'application/json', 'charset=utf-8' ]);
$data = JSON::Syck::Load($res->content);
ok ref $data;
is $data->{hoge}, 'foo';
ok not $data->{private_var};
