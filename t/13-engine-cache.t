#!perl
use strict;
use warnings;
use FindBin::libs;

EngineCacheTest->runtests;

package EngineCacheTest;
use base qw/Test::Class/;
use Test::More skip_all => 'engine caching is obsoleted';
use Sandbox;
use Scalar::Util qw/refaddr/;
use Ridge::URI;
use Ridge::Engine::Factory;

sub retrieve_engine ($) {
    return Ridge::Engine::Factory->instantiate({
        flow      => Ridge::URI->new(shift)->to_flow,
        namespace => 'Sandbox',
    });
}

sub test_cache : Tests {
    ok retrieve_engine('http://d.hatena.ne.jp/naoya/');
    is(
        refaddr retrieve_engine('http://d.hatena.ne.jp/naoya/'),
        refaddr retrieve_engine('http://d.hatena.ne.jp/naoya/')
    );
    isnt(
        refaddr retrieve_engine('http://d.hatena.ne.jp/naoya/'),
        refaddr retrieve_engine('http://d.hatena.ne.jp/naoya/hello'),
    );
}

1;
