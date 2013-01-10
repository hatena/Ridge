#!perl
use strict;
use warnings;
use FindBin::libs;

use Test::Base;
use Ridge::URI;
use Ridge::Engine::Factory;

sub factory {
    ref Ridge::Engine::Factory->instantiate({
        namespace => 'Sandbox',
        flow      => Ridge::URI->new($_[0])->to_flow,
    });
}

run_is 'input' => 'expected';

__END__
===
--- input factory: http://d.hatena.ne.jp
--- expected: Sandbox::Engine::Index

===
--- input factory: http://d.hatena.ne.jp/
--- expected: Sandbox::Engine::Index

===
--- input factory: http://d.hatena.ne.jp/index
--- expected: Sandbox::Engine::Index

=== input factory: http://d.hatena.ne.jp/index.update
--- expected: Sandbox::Engine::Index

===
--- input factory: http://d.hatena.ne.jp/entry
--- expected: Sandbox::Engine::Entry

===
--- input factory: http://d.hatena.ne.jp/unknown
--- expected: Sandbox::Engine
