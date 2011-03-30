#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/t/lib";

use Sandbox;
use Benchmark::Timer;

$ENV{RIDGE_ENV} = 'production';

my $root = "$FindBin::Bin/t";
my $t = Benchmark::Timer->new;

Sandbox->configure({ URI => { use_lite => 1 } });

for (1..10000) {
    $t->start('process');
    my $res = Sandbox->process({
        root => $root,
        uri  => 'http://localhost/',
    });
    $t->stop('process');
    print $res->status_line, "\n";
}

warn scalar $t->reports;

