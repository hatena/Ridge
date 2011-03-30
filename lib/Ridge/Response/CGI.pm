package Ridge::Response::CGI;
use strict;
use warnings;
use base qw/Ridge::Response/;
use CGI::Cookie;

sub cookie {
    shift->add_cookie(CGI::Cookie->new(@_));
}

1;
