use strict;
use warnings;
use Test::More tests => 14;
use FindBin::libs;
use Sandbox::Engine::Attrs;
use Ridge::Test qw/Sandbox/;
use HTTP::Status;

my $engine = Sandbox::Engine::Attrs->new;

ok $engine->can('default');
ok $engine->can('attr_of');
ok $engine->attr_of('default');
ok $engine->is_public('default');
ok $engine->is_public('public');
ok $engine->can('private');
ok not $engine->is_public('private');
ok not $engine->is_public('new');
ok not $engine->is_public('_foobar');
is @{$engine->public_actions}, 2;

is get('/attrs')->code, RC_OK;
is get('/attrs.private')->code, RC_NOT_FOUND;
is get('/attrs.new')->code, RC_NOT_FOUND;
is get('/attrs._foobar')->code, RC_OK; # will fallback to 'default'
