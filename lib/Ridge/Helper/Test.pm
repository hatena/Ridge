package Ridge::Helper::Test;
use strict;
use warnings;
use CLASS;
use base qw/Ridge::Helper/;
use Pod::Usage;

CLASS->mk_accessors(qw/test_name path/);

sub create {
    my $self = shift;
    $self->test_name($self->argv->[0]) or pod2usage({
        -input    => __FILE__,
        -exitval  => 1,
    });
    my $file_name = $self->test_name;
    $file_name =~ s/::/_/g;
    $file_name = lc $file_name;

    my $path = $self->test_name;
    $path =~ s/::/\//;
    $path = sprintf "/%s", lc $path;
    $self->path($path);

    $self->render_file('t', 'app', sprintf("%s.t", $file_name));
}

1;

=pod

=head1 SYNOPSIS

create.pl Test [test_name]

 Examples:
    create.pl test Hello
    create.pl test Hello::World

=head1 AUTHOR

Naoya Ito, C<platform@hatena.ne.jp>

=cut

__DATA__
#!perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use HTTP::Status;
use Ridge::Test '[% h.namespace %]';

is get('[% h.path %]')->code, RC_OK;

1;
