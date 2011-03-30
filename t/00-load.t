#!perl
use strict;
use warnings;

use Test::More tests => 3;

use_ok 'Ridge';
use_ok 'Ridge::Thing';
use_ok 'Ridge::TemplateFile';

# for my $key (keys %ENV) {
#    warn $key, " => ", $ENV{$key}, "\n";
#}
