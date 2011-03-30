#!/usr/bin/env perl
use strict;
use warnings;
use FindBin::libs;
use Benchmark qw/:all/;

use Ridge::URI;
use Ridge::URI::Lite;

my $url = 'http://b.hatena.ne.jp/hotentry.rss?threshold=5';

my $res = timethese(10000, {
    'Ridge::URI'       => sub { return Ridge::URI->new($url)->action },
    'Ridge::URI::Lite' => sub { return Ridge::URI::Lite->new($url)->action }
});

cmpthese( $res );
