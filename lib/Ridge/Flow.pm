package Ridge::Flow;
use strict;
use warnings;
use base qw/Ridge::Thing/;
use CLASS;

my @Fields = qw/path_segments action view/;
CLASS->mk_accessors(@Fields);

sub new_from {
    my ($class, $args) = @_;
    $class->new({
        path_segments => _engine2ps($args->{engine}),
        action        => $args->{action} || '',
        view          => $args->{view}   || '',
    });
}

sub as_key {
    my $self = shift;
    join '|', @{$self->path_segments || []}, $self->action, $self->view;
}

sub to_engine {
    my ($self, $namespace) = @_;
    my $path_segments = $self->path_segments || [];
    join '::', $namespace, 'Engine', _ps2engine(@$path_segments);
}

sub _ps2engine {
    my @segments = @_;
    if (grep { /[^a-z0-9_-]/i } @segments) {
        @segments = ();
    }
    $segments[-1] ||= 'index' if @segments;
    join('::', map { ucfirst } grep { $_ } @segments) || 'Index';
}

sub _engine2ps {
    my $engine = shift;
    $engine =~ s/.*Engine::(.+)$/$1/;
    $engine =~ s/Index$//;
    [ map { lc } split '::', $engine ];
}

1;
