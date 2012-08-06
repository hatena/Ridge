#!perl
use strict;
use warnings;

use Test::More tests => 4;

use_ok 'Ridge';
use_ok 'Ridge::Thing';
use_ok 'Ridge::TemplateFile';

no warnings 'once';
is $Ridge::BACKEND, 'Plack';
