use strict;
use warnings;
use FindBin::libs;

PluginTest->runtests;

package PluginTest;
use base qw/Test::Class/;
use Test::More;
use Sandbox;
use IO::String;
use Log::Dispatch::Handle;
use HTTP::Request;
use HTTP::Message::PSGI;

sub process ($) {
    my $url = shift;
    Sandbox->process( HTTP::Request->new(GET => $url)->to_psgi );
}

sub logger : Tests {
    isa_ok(Sandbox->logger, 'Log::Dispatch');
    my $io = IO::String->new;
    my $logger = Log::Dispatch::Handle->new(name => 'handle', min_level => 'debug', handle => $io);
    Sandbox->logger->add($logger);
    my $res = process('http://d.hatena.ne.jp/private');
    ok ${$io->string_ref} =~ m/d.hatena.ne.jp\/private/;
}

