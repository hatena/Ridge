#!perl
use strict;
use warnings;

ConfigTest->runtests;

package ConfigTest;
use base qw/Test::Class/;
use Test::More;
use Test::Singleton;
use Ridge::Config;
BEGIN { undef $ENV{RIDGE_ENV}  };

sub test_instance : Test(1) {
    my $config = Ridge::Config->new;
    ok ref $config;
}

# sub test_singleton : Tests(8) {
#     is_singleton('Ridge::Config', 'instance', 'instance');
#     is_singleton('Ridge::Config', 'new', 'instance');
# }

sub test_merge : Tests {
    my $config = Ridge::Config->new;
    $config->param(
        foo  => 'bar',
        bar  => 'baz',
        hoge => 'hage',
    );

    $config->param(
        foo => 'barbar',
        bar => 'bazbaz',
    );

    is $config->param('foo'), 'barbar';
    is $config->param('bar'), 'bazbaz';
    is $config->param('hoge'), 'hage';
    ok not $config->param('piyo');
}

sub test_app_config : Tests {
    my $config = Ridge::Config->new;
    $config->app_config->param(
        uri => 'http://d.hatena.ne.jp/',
        dsn          => 'dbi:msyql:diary',
        service_name => 'Hatena::Diary',
    );

    $config->app_config('development')->param(
        uri => 'http://dtest.hatena.ne.jp/',
        dsn => 'dbi:mysql:dtest',
    );

    $config->app_config('null')->param(
        unko => 'unko',
    );

    is $config->app_config->param('uri'), 'http://d.hatena.ne.jp/';
    is $config->app_config->param('dsn'), 'dbi:msyql:diary';
    is $config->app_config->param('service_name'), 'Hatena::Diary';
    ok not $config->app_config->param('unko');

    is $config->app_config('development')->param('uri'), 'http://dtest.hatena.ne.jp/';
    is $config->app_config('development')->param('dsn'), 'dbi:mysql:dtest';
    is $config->app_config('development')->param('service_name'), 'Hatena::Diary';
    ok not $config->app_config('development')->param('unko');
}

