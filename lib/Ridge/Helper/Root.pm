package Ridge::Helper::Root;
use strict;
use warnings;
use base qw/Ridge::Helper/;

sub create {
    my $self = shift;
    $self->render_module('', join '::', $self->namespace, 'Engine');
}

1;

__DATA__
package [% h.namespace %]::Engine;
use strict;
use warnings;
use Ridge::Engine -Base;

sub default : Public {}

1;
