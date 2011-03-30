package Test::Ridge::Trigger;
BEGIN {
    # Ridge sucks
    $INC{'Test/Ridge/Trigger/Engine.pm'} = __FILE__;
    $INC{'Test/Ridge/Trigger/Engine/Index.pm'} = __FILE__;
};

use strict;
use warnings;
use base qw(Ridge);
use FindBin;
__PACKAGE__->configure({
    plugins         => [],
    root            => $FindBin::Bin,
    static_path     => ['^/images', '^/js', '^/css'],
    URI             => '',
    app_config      => {
        default => {
        },
    }
});

our $trigger = {};

__PACKAGE__->add_trigger(before_dispatch => sub {
    my ($self, $engine) = @_;
    push @{ $trigger->{before_dispatch} ||= [] }, [ $self, $engine ];
    1;
});

__PACKAGE__->add_trigger(after_dispatch => sub {
    my ($self, $engine) = @_;
    push @{ $trigger->{after_dispatch} ||= [] }, [ $self, $engine ];
    1;
});

package Test::Ridge::Trigger::Engine;
use strict;
use warnings;
use Ridge::Engine -Base;


package Test::Ridge::Trigger::Engine::Index;
use strict;
use warnings;
use Test::Ridge::Trigger::Engine -Base;
use Ridge::Exceptions;

sub default : Public {
    my ($self, $r) = @_;
    $r->res->content('ok');
}

sub throw403 : Public {
    my ($self, $r) = @_;
    Ridge::Exception::RequestError->throw(code => 403);
}

package main;
use Test::Most;
use HTTP::Request;
use HTTP::Message::PSGI;

sub request {
    my $env = HTTP::Request->new(@_)->to_psgi;
    $ENV{GATEWAY_INTERFACE} = 'CGI';
    $Test::Ridge::Trigger::trigger = {
        before_dispatch => [],
        after_dispatch  => []
    };
    my $res = res_from_psgi(Test::Ridge::Trigger->process($env, {}));
}

subtest 'normal trigger' => sub {
    my $res = request(GET => 'http://example.com/');
    is $res->header('X-Ridge-Dispatch'), 'Test::Ridge::Trigger::Engine::Index#default';
    is scalar @{ $Test::Ridge::Trigger::trigger->{before_dispatch} }, 1;
    is scalar @{ $Test::Ridge::Trigger::trigger->{after_dispatch} }, 1;
    isa_ok $Test::Ridge::Trigger::trigger->{before_dispatch}->[0]->[0], 'Ridge';
    isa_ok $Test::Ridge::Trigger::trigger->{before_dispatch}->[0]->[1], 'Ridge::Engine';
};

subtest 'request error' => sub {
    my $res = request(GET => 'http://example.com/index.throw403');
    is $res->header('X-Ridge-Dispatch'), 'Test::Ridge::Trigger::Engine::Index#throw403';
    is scalar @{ $Test::Ridge::Trigger::trigger->{before_dispatch} }, 1;
    is scalar @{ $Test::Ridge::Trigger::trigger->{after_dispatch} }, 1;
    isa_ok $Test::Ridge::Trigger::trigger->{before_dispatch}->[0]->[0], 'Ridge';
    isa_ok $Test::Ridge::Trigger::trigger->{before_dispatch}->[0]->[1], 'Ridge::Engine';
};

done_testing;

