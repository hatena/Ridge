package Ridge::Helper::Ridge;
use strict;
use warnings;
use base qw/Ridge::Helper/;

sub create {
    my $self = shift;
    $self->render_module('', $self->namespace);
}

1;

__DATA__
package [% h.namespace %];
use strict;
use warnings;
use base qw/Ridge/;

__PACKAGE__->configure;

1;
