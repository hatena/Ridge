package Sandbox::Filter::Test;
use strict;
use warnings;

sub filter {
    my ($class, $r) = @_;
    $r->res->content(sprintf "filtered by " . __PACKAGE__);
    1;
}

1;

