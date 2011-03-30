#!perl
use strict;
use warnings;
use FindBin::libs;

ConfigureTest->runtests;

package ConfigureTest;
use base qw/Test::Class/;
use Test::More;
use Sakura;

sub test_configure : Test(3) {
    is(Sakura->config->param('foo'), 'bar');     # Sakura::Base.
    is(Sakura->config->param('bar'), 'bazbaz');  # overriding
    is(Sakura->config->param('hoge'), 'hage');   # append
}

sub test_app_config : Tests {
    is(Sakura->app_config->param('name'), 'DEFAULT');
    is(Sakura->app_config->param('age'), 20);

    local $ENV{RIDGE_ENV} = 'com';
    is(Sakura->app_config->param('name'), 'COM');
    is(Sakura->app_config->param('age'), 20);
    is(Sakura->app_config->param('country'), 'America'); # override

    # append
    local $ENV{RIDGE_ENV} = 'jp';
    is(Sakura->app_config->param('name'), 'JP');
    is(Sakura->app_config->param('age'), 20);
}
