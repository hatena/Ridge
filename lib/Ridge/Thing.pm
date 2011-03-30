package Ridge::Thing;
use strict;
use warnings;
use base qw/Ridge::Object/;
use Carp qw/croak/;
use CLASS;

sub param {
    if (@_ == 1) {
        return keys %{$_[0]};
    }

    if (@_ == 2) {
        return $_[0]->{$_[1]};
    }

    if (@_ & 1 == 0) {
        croak sprintf "%s : You gave me an odd number of parameters to param()", CLASS;
    }

    for (my $i = 1; $i < @_; $i += 2) {
        $_[0]->{$_[$i]} = $_[$i + 1];
    }
}

sub clear {
    my $self = shift;
    delete $self->{$_} for $self->param;
}

sub to_hash {
    my $self = shift;
    # scalar { map { $_ => $self->get($_) } $self->param };
    scalar { map { $_ => $self->{$_} } $self->param };
}

sub to_yaml {
    my $self = shift;
    require YAML::Syck;
    YAML::Syck::Dump($self->to_hash);
}

sub to_json {
    my $self = shift;
    require JSON::Syck;
    JSON::Syck::Dump($self->to_hash);
}

1;
