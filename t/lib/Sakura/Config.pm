package Sakura::Config;
use strict;
use warnings;
use CLASS;
use Path::Class qw/file/;
use base qw/Sakura::Base::Config/;

CLASS->setup({
    static_path => ['^/images'],
    app_config      => {
        default => {
            uri => 'http://sakura.hatena.com/',
            dsn => 'dbi:mysql:sakura;host=127.0.0.1',
        },
        devel   => {
            uri => 'http://dev.sakura.hatena.com/',
            dsn => 'dbi:mysql:sakura_devel;host=127.0.0.1'
        }
    }
});

1;
