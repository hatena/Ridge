package Ridge::Thing::Singleton;
use strict;
use warnings;
use base qw/Ridge::Thing Class::Singleton/;

sub new {
    my $class = shift;
    $class->instance(@_);
}

sub _new_instance {
    my $class = shift;
    $class->SUPER::new(@_);
}

1;
