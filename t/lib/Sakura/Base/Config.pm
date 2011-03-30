package Sakura::Base::Config;
use strict;
use warnings;
use CLASS;
use Path::Class qw/file/;
use base qw/Ridge::Config/;

CLASS->setup({
    root            => $FindBin::Bin,
    plugins         => ['Hello','Cat','Debug','XFramework'],
    static_path     => ['^/images','^/js','^/css'],

    'Plugin::Hello' => {
        message => 'World',
        counter => 0,
    },

    cookie_domain   => '.hatena.ne.jp',
    app_config      => {
        default => {
            uri  => 'http://base.sakura.hatena.com/',
            dsn  => 'dbi:mysql:sakura_base;host=127.0.0.1',
            path => '/foo/bar',
        },
        devel   => {
            uri  => 'http://dev.base.sakura.hatena.com/',
            dsn  => 'dbi:mysql:sakura_base_devel;host=127.0.0.1'
        }
    }
});

1;
