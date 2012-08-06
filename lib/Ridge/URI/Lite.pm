package Ridge::URI::Lite;
use strict;
use warnings;
use base qw/Class::Accessor::Lvalue::Fast Class::Data::Inheritable/;
use overload '""' => 'as_string';

__PACKAGE__->mk_classdata('filter');
__PACKAGE__->mk_accessors(qw/url _action _root _view _segs _params/);

use URI;
use URI::QueryParam;
use Ridge::Flow;

sub new {
    my ($class, $url) = @_;
    my $self = $class->SUPER::new;
    if (not ref $url) {
        $url = URI->new( $url );
    }
    $self->url     = $url;
    $self->_params = {};

    if ($class->filter){
        $class->filter->( $self );
    }

    return $self;
}

sub new_abs {
    my $class = shift;
    my $self = $class->SUPER::new;

    $self->url     = URI->new_abs(@_);
    $self->_params = {};

    if ($class->filter){
        $class->filter->( $self );
    }

    return $self;
}

sub host {
    my $self = shift;
    $self->url->host(@_);
}

sub port {
    my $self = shift;
    $self->url->port(@_);
}

sub host_port {
    my $self = shift;
    $self->url->host_port(@_);
}

sub scheme {
    my $self = shift;
    $self->url->scheme(@_);
}

sub path {
    my $self = shift;
    $self->url->path(@_);
}

sub path_query {
    my $self = shift;
    $self->url->path_query(@_);
}

sub query_form {
    my $self = shift;
    $self->url->query_form(@_);
}

sub query_param {
    my $self = shift;
    $self->url->query_param(@_);
}

sub query_param_append {
    my $self = shift;
    $self->url->query_param_append(@_);
}

sub query_param_delete {
    my $self = shift;
    $self->url->query_param_delete(@_);
}

sub query_form_hash {
    my $self = shift;
    $self->url->query_form_hash(@_);
}

sub query_keywords {
    my $self = shift;
    $self->url->query_keywords(@_);
}

sub path_segments {
    my $self = shift;

    if (my $segs = $self->_segs) {
        return $segs;
    }

    my @segs = $self->url->path_segments;

    if ($segs[0] eq '') {
        shift @segs;
    }

    if ($segs[-1] =~ m/^(.+?)\./) {
        $segs[-1] = $1;
    }

    return $self->_segs = \@segs;
}

sub _path_segments {
    my $self = shift;
    $self->url->path(@_);
}

sub as_string {
    $_[0]->url->as_string;
}

sub action {
    my $self = shift;
    if (my $action = $self->_action) {
        return $action;
    }

    my @path = $self->_path_segments;
    if ($path[-1] and $path[-1]  =~ m!\.([^\.]*)!) {
        return $self->_action = $1;
    }

    return;
}

sub view {
    my $self = shift;
    if (my $view = $self->_view) {
        return $view;
    }

    my @path = $self->_path_segments;
    if ($path[-1] and $path[-1] =~ m!\.(html|json|yaml)$!) {
        return $self->_view = $1;
    }

    return;
}

sub root {
    my $self = shift;
    if (my $root = $self->_root) {
        return $root;
    } else{
        my $root = $self->url->clone;
        $root->path_query('/');
        return $self->_root = $root;
    }
}

sub to_flow {
    my $self = shift;

    return Ridge::Flow->new({
        path_segments => $self->path_segments || [],
        action        => $self->action || '',
        view          => $self->view || '',
        device        => $self->device || '',
    });
}

sub param {
    my ($self, $key, $value) = @_;
    (@_ > 2)
        ? $self->_params->{$key} = $value
        : $self->_params->{$key};
}

sub as_uri {
    my $self = shift;
    return $self->url->clone;
}

sub clone {
    my $self = shift;
    $self->url->clone(@_);
}

sub device {
    my ($self) = @_;
    $self->param('device');
}

1;
