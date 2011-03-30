package Ridge::ActionFilter;
use strict;
use warnings;
use base qw/Ridge::Object/;
use CLASS;

sub new {
    my ($class, $filter) = @_;
    my $self = $class->SUPER::new({ filter => $filter });
    bless $self, $class;
}

CLASS->mk_accessors(qw/filter/);

sub run {
    my ($self, $r, $engine) = @_;
    my $ref = ref $self->filter;
    if ($ref and $ref eq 'CODE') {
        return $self->filter->($r);
    }

    if (not $ref) {
        my $symbol = $self->filter;
        if ($symbol !~ m/::/) {
            $engine->can($symbol)
                ? return $engine->$symbol($r)
                : die sprintf 'Filter error: Unknown symbol "%s" was specified', $symbol;
        } else {
            $symbol->require or die $@;
            return $symbol->filter($r);
        }
    }
    1;
}

1;
