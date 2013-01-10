package Ridge::Daemon;
use strict;
use warnings;

use Ridge::Util qw/logger/;

sub msg ($) {
    logger->info(shift);
}

our $VERSION = 0.02;

1;
