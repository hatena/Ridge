#!/usr/bin/env perl
use Test::More qw/no_plan/;
use FindBin;
use Path::Class qw/file/;
use Data::Dumper;
use FindBin;

BEGIN {  use_ok Ridge::Config };

## new instance
my $config = Ridge::Config->new;
ok ref $config;
is $config->param('charset'), 'utf-8';

## load from yaml
$config = Ridge::Config->load(file($FindBin::Bin, 'config.yml'));
ok ref $config;
is $config->param('root'), $FindBin::Bin;
isa_ok $config->param('root'), 'Path::Class::Dir';
is_deeply $config->param('plugins'), [qw/Hello Cat Debug XFramework/];
is_deeply $config->param('static_path'), ['^/images', '^/js', '^/css'];
is_deeply $config->param('Plugin::Hello'), { message => 'World', counter =>  0 };

## app_config interface
is $config->app_config->param('uri'), 'http://sandbox.hatena.com/';

## static path for config.yml
Ridge::Config->config_path(file($FindBin::Bin, 'config.yml'));
$config = Ridge::Config->load;
Ridge::Config->config_path('');
$config = Ridge::Config->load(file($FindBin::Bin, 'config.yml'));

## dump
ok $config->dump;
is $config->dump, Data::Dumper::Dumper($config->to_hash);
