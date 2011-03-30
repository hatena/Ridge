package Ridge::Plugin::Debug;
use strict;
use warnings;
use base qw/Ridge::Plugin/;

sub ridge : Method {
    my ($self, $r, @args) = @_;
    $r;
}

sub plugin : Method {
    my ($self, $r, @args) = @_;
    $self;
}

1;

