package Sandbox::Config;
use strict;
use warnings;
use base qw/Ridge::Config/;
use Path::Class qw/file/;

__PACKAGE__->config_path(
    file(__PACKAGE__->find_root, 'config.yml')
);

1;
