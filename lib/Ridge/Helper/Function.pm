package Ridge::Helper::Function;
use strict;
use warnings;
use CLASS;
use base qw/Ridge::Helper/;

CLASS->mk_accessors(qw/function_name/);

sub create {
    my $self = shift;
    $self->function_name($self->argv->[0]) or pod2usage({
        -input    => __FILE__,
        -exitval  => 1,
    });
    $self->render_module(Function => $self->function_name);
}

1;

=pod

=head1 SYNOPSIS

create.pl function [function_name]

 Examples:
    create.pl function PermissionCheck
    create.pl function FooFunction

=head1 AUTHOR

Naoya Ito, C<platform@hatena.ne.jp>

=cut

__DATA__
package [% h.namespace %]::Function::[% h.function_name %];
use strict;
use warnings;
use base qw/Ridge::Function/;

sub process {
    my ($self, $r) = @_;
    1;
}

1;
