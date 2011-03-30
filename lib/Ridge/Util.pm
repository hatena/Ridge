package Ridge::Util;
use strict;
use warnings;
use Exporter::Lite;
use Carp qw/carp/;

our @EXPORT_OK = qw/debug trim trimx logger deprecated/;

sub httpd_interface () { # _deprecated
    'CGI'
}

sub debug (@) {
    carp "[alert] Ridge::Util debug is obsolute, please use logger.";
    carp "[debug] ", @_ if $ENV{RIDGE_DEBUG};
}

sub logger () {
    return Ridge->logger;
}

sub trim ($) {
    local $_ = shift;
    s/^\s+//;
    s/\s+$//;
    $_;
}

sub deprecated {
    my $alt = shift;
    my $method = (caller(1))[3];
    Carp::carp("$method is deprecated. Use '$alt' instead.") if ($ENV{PLACK_ENV} || '') ne 'production';
}

1;
