#!perl
use strict;
use warnings;
use FindBin::libs;
use Sandbox;
use Test::More qw/no_plan/;
use HTTP::Request::Common;
use HTTP::Message::PSGI;

my $res = Sandbox->process(HTTP::Request->new(GET => 'http://localhost/index.hello?foo=bar')->to_psgi);
$res = res_from_psgi $res;
is $res->code, 200;
is $res->content, 'Hello';

my $sandbox = Sandbox->new;
can_ok $sandbox, 'hello';
can_ok $sandbox, 'cat';
can_ok $sandbox, 'ridge';
can_ok $sandbox, 'plugin';
is $sandbox->hello_config->{message}, 'World';

is(Sandbox->new->plugin, Sandbox->new->plugin);
isnt(Sandbox->new->ridge, Sandbox->new->ridge);

my $plugin = Sandbox->new->plugin;
$plugin->stash->param(foo => 'bar');
is $plugin->stash->param('foo'), 'bar';
is (Sandbox->new->plugin->stash->param('foo'), undef);

