#!/usr/local/bin/perl
use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
use lib File::Spec->catdir($FindBin::Bin, '..', '..', 'lib');
use Ridge::Daemon;
use Path::Class qw/dir/;
use Getopt::Long;

my $env;
GetOptions('e=s' => \$env);

local $ENV{RIDGE_ENV} = $env if $env;

Ridge::Daemon->run('Sandbox', {
    root => dir($FindBin::Bin)->parent,
    port => 3000,
});
