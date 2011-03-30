package Ridge::Engine::Factory;
use strict;
use warnings;
use Carp;
use UNIVERSAL::require;

sub instantiate {
    my ($class, $args) = @_;
    for (qw/flow namespace/) {
        croak "argument '$_' must be required" if not defined $args->{$_};
    }

    my $flow = $args->{flow};
    my $engine = $flow->to_engine($args->{namespace});
    $engine->require and return $engine->new;

    ## fallback to the default Engine
    if ($@ and $@ =~ m/Can\'t locate .*?Engine.*? in \@INC/) {
        $engine = default_engine($args->{namespace});
        $engine->require or die $@;
        return $engine->new;
    } else {
        die $@;
    }
}

sub default_engine {
    join '::', $_[0], 'Engine';
}

1;
