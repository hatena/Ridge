#!perl
use strict;
use warnings;
use FindBin::libs;
use Test::More 'no_plan';

BEGIN {
    $ENV{RIDGE_ENV} = 'devel';
}

use Ridge::Test 'Sandbox';
is get('/index.app_uri')->content, 'http://dev.sandbox.hatena.com/';

