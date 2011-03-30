package Ridge::Helper::Engine;
use strict;
use warnings;
use CLASS;
use base qw/Ridge::Helper/;
use Pod::Usage;

CLASS->mk_accessors(qw/engine_name/);

sub create {
    my $self = shift;
    $self->engine_name($self->argv->[0]) or pod2usage({
        -input    => __FILE__,
        -exitval  => 1,
    });
    $self->render_module(Engine => $self->engine_name);

    my $test = Ridge::Helper->new({
        namespace => $self->namespace,
        root      => $self->root,
        argv      => [ 'Test', $self->argv->[0] ]
    });
    $test->run;
}

1;

=pod

=head1 SYNOPSIS

create.pl engine [engine_name]

 Examples:
    create.pl engine Hello
    create.pl engine Hello::World

=head1 AUTHOR

Naoya Ito, C<platform@hatena.ne.jp>

=cut

__DATA__
package [% h.namespace %]::Engine::[% h.engine_name %];
use strict;
use warnings;
use [% h.namespace %]::Engine -Base;

sub default : Public {
    my ($self, $r) = @_;
    $r->res->content('[% h.namespace %]');
}

1;
