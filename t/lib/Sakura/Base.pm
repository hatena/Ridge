package Sakura::Base;
use strict;
use warnings;
use CLASS;
use base qw/Ridge/;

CLASS->configure({
    foo => 'bar',
    bar => 'baz',
    app_config => {
        default => {
            name => 'DEFAULT',
            age  => 20,
        },
        com => {
            name    => 'COM',
            country => 'USA',
        },
    }
});

1;
