#!/usr/bin/env perl
use Test::More qw/no_plan/;
use FindBin;
use Path::Class qw/file/;
use Data::Dumper;
use FindBin;
use FindBin::libs;

use Sakura::Config;
use Sakura::Base::Config;

## new instance
my $config = Sakura::Base::Config->new;
ok ref $config;
is $config->param('charset'), 'utf-8';

$config = Sakura::Base::Config->load;
ok ref $config;
is $config->param('root'), $FindBin::Bin;
isa_ok $config->param('root'), 'Path::Class::Dir';
is_deeply $config->param('plugins'), [qw/Hello Cat Debug XFramework/];
is_deeply $config->param('static_path'), ['^/images', '^/js', '^/css'];
is_deeply $config->param('Plugin::Hello'), { message => 'World', counter =>  0 };

## app_config interface
is $config->app_config->param('uri'), 'http://base.sakura.hatena.com/';
is $config->app_config->param('path'), '/foo/bar';

## sub class
my $config = Sakura::Config->new;
ok ref $config;
is $config->param('charset'), 'utf-8';

$config = Sakura::Config->load;
ok ref $config;
is $config->param('root'), $FindBin::Bin;
isa_ok $config->param('root'), 'Path::Class::Dir';
is_deeply $config->param('plugins'), [qw/Hello Cat Debug XFramework/];
is_deeply $config->param('static_path'), ['^/images'];
is_deeply $config->param('Plugin::Hello'), { message => 'World', counter =>  0 };

## app_config interface
is $config->app_config->param('uri'), 'http://sakura.hatena.com/';
is $config->app_config->param('path'), '/foo/bar';
