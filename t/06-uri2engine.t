#!perl
use strict;
use warnings;
use Test::Base;

use Ridge::URI;
use Ridge::Config;
# use Ridge::Engine::Factory;

sub factory {
    Ridge::URI->new($_[0])->to_flow->to_engine('Sandbox'),
}

__END__
=== 
--- input factory: http://d.hatena.ne.jp
--- expected: Sandbox::Engine::Index

===
--- input factory: http://d.hatena.ne.jp/
--- expected: Sandbox::Engine::Index

===
--- input factory: http://d.hatena.ne.jp/entry
--- expected: Sandbox::Engine::Entry

===
--- input factory: http://d.hatena.ne.jp/entry.create
--- expected: Sandbox::Engine::Entry

===
--- input factory: http://d.hatena.ne.jp/config
--- expected: Sandbox::Engine::Config

===
--- input factory: http://d.hatena.ne.jp/config/
--- expected: Sandbox::Engine::Config::Index

===
--- input factory: http://d.hatena.ne.jp/config/detail
--- expected: Sandbox::Engine::Config::Detail

===
--- input factory: http://d.hatena.ne.jp/config/detail.update
--- expected: Sandbox::Engine::Config::Detail

===
--- input factory: http://d.hatena.ne.jp/config/feed/detail
--- expected: Sandbox::Engine::Config::Feed::Detail

===
--- input factory: http://d.hatena.ne.jp/config/feed/detail/
--- expected: Sandbox::Engine::Config::Feed::Detail::Index

===
--- input factory: http://d.hatena.ne.jp/config/feed/detail/index.update
--- expected: Sandbox::Engine::Config::Feed::Detail::Index

===
--- input factory: http://d.hatena.ne.jp/config/feed/detail/index.json
--- expected: Sandbox::Engine::Config::Feed::Detail::Index

===
--- input factory: http://d.hatena.ne.jp/config_test
--- expected: Sandbox::Engine::Config_test

===
--- input factory: http://d.hatena.ne.jp/config-test
--- expected: Sandbox::Engine::Config-test

