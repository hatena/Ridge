package Ridge::Plugin;
use strict;
use warnings;
use base qw/Class::Component::Plugin/;

sub initialize {}

sub stash {
    my $self = shift;
    @_ ? $self->{_stash} = shift : $self->{_stash};
}

sub cleanup {
    shift->{_stash} = undef;
}

1;
