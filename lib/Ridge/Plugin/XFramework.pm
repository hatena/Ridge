package Ridge::Plugin::XFramework;
use strict;
use warnings;
use base qw/Ridge::Plugin/;
use Plack;

sub initialize {
    my ($plugin, $r) = @_;
    $r->res->headers->push_header(
        'X-Framework' => sprintf("Ridge/%s Plack/%s", Ridge->VERSION, $Plack::VERSION)
    );
}

1;
