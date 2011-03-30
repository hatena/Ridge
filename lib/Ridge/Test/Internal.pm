package Ridge::Test::Internal;
use strict;
use warnings;
use base qw/Ridge::Object/;
use UNIVERSAL::require;
use Test::More;
use Carp;
use FindBin;
use HTTP::Cookies;
use HTTP::Request::Common ();
use HTTP::Request::AsCGI;
use Plack::Test;
use HTTP::Message::PSGI;
use base qw/Class::Accessor::Fast/;
my @methods = qw/path method host cookie_domain/;
__PACKAGE__->mk_accessors(@methods);

our @EXPORT = qw/run test GET POST PUT HEAD/;

our $app;

sub import {
    my ($class, $namespace, @args) = @_;
    my $callpkg = scalar caller;
    $namespace or croak "Usage: use Ridge::Test::Internal 'MyApp'";
    $namespace->require or die $@;
    $app = $namespace;

    {
        no strict 'refs';
        *{"$callpkg\::_APP"} = sub {
            my $env = shift;
            $namespace->process($env, {});
        };
    };

    for my $func (@EXPORT) {
        no strict 'refs';
        *{"$callpkg\::$func"} = \&$func;
    }
}

sub request {
    my ($req) = @_;
    my $callpkg = caller(1);
    my $res;
    my $app;
    {
        no strict 'refs';
        $app = \&{"$callpkg\::_APP"};
    };
    test_psgi $app, sub {
        my $cb = shift;
        $res = $cb->($req);
    };
    $res;
}

foreach my $method (qw(GET POST PUT HEAD)) {
    no strict 'refs';
    *{__PACKAGE__ . "::$method"} = sub {
        my $code = pop;
        my $path = shift;

        local $ENV{RIDGE_ENV} = 'test';

        my $env = HTTP::Request::Common->can($method)->(URI->new_abs($path, $app->app_config->param('uri')), @_)->to_psgi;

        local $_ = $app->test_process($env, { root => $app->config->param('root') });
        $code->();
    };
}


1;
