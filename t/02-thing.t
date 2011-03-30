#!perl
use strict;
use warnings;

ThingTest->runtests;

package ThingTest;
use base qw/Test::Class/;
use Test::More;
use Ridge::Thing;
use YAML::Syck;
use JSON::Syck;

sub test_accessor : Test(6) {
    Ridge::Thing->mk_accessors(qw/foo bar/);

    ok my $thing = Ridge::Thing->new;
    ok $thing->can('foo');
    ok $thing->can('bar');

    $thing->foo('foo');
    is $thing->foo, 'foo';
    is $thing->bar, undef;
    is $thing->param('foo'), 'foo';
}

sub test_param : Test(8) {
    my $thing = Ridge::Thing->new({ foo => 'bar' });
    ok $thing->can('param');
    is $thing->param('foo'), 'bar';

    $thing->param(baz => 'bar');
    is $thing->param('baz'), 'bar';

    $thing->param(
        hoge => 'hage',
        moge => 'piyo',
    );
    is $thing->param('hoge'), 'hage';
    is $thing->param('moge'), 'piyo';

    is $thing->param, 4;

    $thing->param(foo => 'bar');
    is $thing->param('foo'), 'bar';

    $thing->param(foo => undef);
    is $thing->param('foo'), undef;
}

sub test_clear : Test(1) {
    my $thing = Ridge::Thing->new({ foo => 'bar' });
    $thing->param(baz => 'bar');
    $thing->clear;
    is $thing->param, 0;
}

sub test_to_hash : Test(2) {
    my $thing = Ridge::Thing->new({ foo => 'bar' });
    $thing->param(baz => 'bar');
    is ref $thing->to_hash, 'HASH';
    is_deeply $thing->to_hash, { foo => 'bar', baz => 'bar' }
}

sub test_to_json : Test(2) {
    my $thing = Ridge::Thing->new({ foo => 'bar', bar => 'baz' });
    my $json = $thing->to_json;
    ok $json;
    my $object = JSON::Syck::Load($json);
    is_deeply $thing, $object;
}

sub test_to_yaml : Test(2) {
    my $thing = Ridge::Thing->new({ foo => 'bar', bar => 'baz' });
    my $yaml = $thing->to_yaml;
    ok $yaml;
    my $object = YAML::Syck::Load($yaml);
    is_deeply $thing, $object;
}

1;
