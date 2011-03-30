use strict;
use warnings;
use Test::More qw/no_plan/;

use FindBin::libs;
use Sandbox;
use Plack;

use HTTP::Request::Common;
use HTTP::Message::PSGI;

my $url = 'http://localhost/';
my $res = Sandbox->process(HTTP::Request->new(GET => $url)->to_psgi);
$res = res_from_psgi $res;
ok $res;
ok $res->headers->header('X-Framework');
is $res->headers->header('X-Framework'), sprintf("Ridge/%s Plack/%s", Ridge->VERSION, $Plack::VERSION);
