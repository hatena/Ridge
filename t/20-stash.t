#!perl
use strict;
use warnings;
use FindBin::libs;
use Test::More 'no_plan';
use Ridge::Stash;

my $stash = Ridge::Stash->new({
    hoge => 'foo',
    bar  => 'baz',
    piyo => 'hage',
});

is $stash->param('hoge'), 'foo';
is $stash->param('bar'), 'baz';
is $stash->param('piyo'), 'hage';

$stash->expose_param([qw/hoge piyo/]);
my $exposed = $stash->exposed_params;
is $exposed->param('hoge'), 'foo';
ok not $exposed->param('bar');
is $exposed->param('piyo'), 'hage';

$stash->expose_param([qw/hoge/]);
$exposed = $stash->exposed_params;
is $exposed->param('hoge'), 'foo';
ok not $exposed->param('bar');
ok not $exposed->param('piyo');
