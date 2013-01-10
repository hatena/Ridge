#!perl
use strict;
use warnings;
use Test::Base;
use Ridge::Flow;

sub e2ps {
    Ridge::Flow::_engine2ps($_[0]);
}

run_is_deeply 'input' => 'expected';

__END__
===
--- input e2ps: Sandbox::Engine::Hello
--- expected eval
['hello']
===
--- input e2ps: Sandbox::Engine::Foo
--- expected eval
['foo']
===
--- input e2ps: Sandbox::Engine::Foo::Bar
--- expected eval
['foo', 'bar']
===
--- input e2ps: Sandbox::Engine::Foo::Bar::Baz
--- expected eval
['foo', 'bar', 'baz']
===
--- input e2ps: Sandbox::Engine::Index
--- expected eval
[]
