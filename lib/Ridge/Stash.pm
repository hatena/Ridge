package Ridge::Stash;
use strict;
use warnings;
use base qw/Ridge::Thing/;
use CLASS;

CLASS->mk_accessors(qw/expose_param/);

sub exposed_params {
    my $self = shift;
    my $data;
    if (my $exposes = $self->expose_param) {
        if (ref($exposes) eq 'ARRAY') {
            my %match = map { $_ => 1 } @$exposes;
            $data = Ridge::Thing->new({ map {$match{$_} ? ($_ => $self->param($_)) : () } keys %{$self} });
        } else {
            $data = Ridge::Thing->new({ $exposes => $self->param($exposes) });
        }
    } else {
        $data = $self;
    }
    $data;
}

# sub DESTROY {
#    warn sprintf "%s: DESTROYED!", __PACKAGE__;
#}

1;
