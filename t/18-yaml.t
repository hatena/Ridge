#!perl
use strict;
use warnings;
use FindBin::libs;
use Ridge::Test 'Sandbox';
use Test::More 'no_plan';
use YAML::Syck;

my $res = get('/index.yaml');
is $res->code, 200;
ok ref YAML::Syck::Load($res->content);
