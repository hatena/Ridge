# A test application for inheritance of Ridge->configure
package Sakura;
use strict;
use warnings;
use base qw/Sakura::Base/;
use CLASS;

Sakura->configure({
    hoge => 'hage',
    bar  => 'bazbaz',
    app_config => {
        jp => {
            name => 'JP',
        },
        com => {
            country => 'America',
        }
    }
});

1;
