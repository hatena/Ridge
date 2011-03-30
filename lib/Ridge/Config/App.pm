package Ridge::Config::App;
use strict;
use warnings;
use base qw/Ridge::Thing/;
use CLASS;

CLASS->mk_accessors(qw/default env __parent_accessor__/);

sub param {
    my $self = shift;
    my $retval = $self->SUPER::param(@_);
    return $retval if (defined $retval);
    if ($self->__parent_accessor__) {
        return $self->__parent_accessor__->param(@_);
    } else {
        return $self->default->param(@_);
    }
}

1;
