package Ridge::Helper::Filter;
use strict;
use warnings;
use CLASS;
use base qw/Ridge::Helper/;
use Pod::Usage;

CLASS->mk_accessors(qw/filter_name/);

sub create {
    my $self = shift;
    $self->filter_name($self->argv->[0]) or pod2usage({
        -input    => __FILE__,
        -exitval  => 1,
    });
    $self->render_module(Filter => $self->filter_name);
}

1;

=pod

=head1 SYNOPSIS

create.pl filter [filter_name]

 Examples:
    create.pl filter Mobile
    create.pl filter FooFilter

=head1 AUTHOR

Naoya Ito, C<platform@hatena.ne.jp>

=cut

__DATA__
package [% h.namespace %]::Filter::[% h.filter_name %];
use strict;
use warnings;
use base qw/Ridge::Filter/;

sub filter {
    my ($self, $r, $text) = @_;
    $text =~ s/foo/bar/g;
    $text;
}

1;
