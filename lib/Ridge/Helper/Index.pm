package Ridge::Helper::Index;
use strict;
use warnings;
use base qw/Ridge::Helper/;

sub create {
    my $self = shift;
    $self->render_module(Engine => 'Index');

    my $test = Ridge::Helper->new({
        namespace => $self->namespace,
        root      => $self->root,
        argv      => [ 'Test', 'Index' ]
    });
    $test->run;
}

1;

__DATA__
package [% h.namespace %]::Engine::Index;
use strict;
use warnings;
use [% h.namespace %]::Engine -Base;

sub default : Public {
    my ($self, $r) = @_;
    $r->res->content_type('text/plain');
    $r->res->content('Welcome to the Ridge world!');
}

1;
