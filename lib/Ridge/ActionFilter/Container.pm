package Ridge::ActionFilter::Container;
use strict;
use warnings;
use base qw/Ridge::Object/;
use Carp qw/croak/;

use Ridge::ActionFilter;
use Ridge::Util qw/trim/;

use HTTP::Status;

sub _list2array ($) {
    my $list = shift;
    (ref $list and ref $list eq 'ARRAY') ? @{$list} : $list;;
}

sub _init {
    my $self = shift;
    $self->{filters} = {}; # $self->{filters}->{action_name} => []
}

sub retrieve {
    my ($self, $action) = @_;
    $action or croak "missing action name as argument";
    return $self->{filters}->{$action};
}

sub append {
    my ($self, %filter) = @_;
    for my $key (keys %filter) {
        for my $action (map { trim $_ } split ',', $key) {
            if (!$self->has_filter($action, $key, %filter)) {
                push(
                    @{$self->{filters}->{$action}},
                    map { Ridge::ActionFilter->new($_) } _list2array($filter{$key})
                );
            }
        }
    }
}

sub has_filter {
    my ($self, $action, $key, %filter) = @_;
    for my $_filter (@{$self->{filters}->{$action}}) {
        if ($_filter->filter eq _list2array($filter{$key})) {
            return 1;
        }
    }
    return 0;
}

sub prepend {
    my ($self, %filter) = @_;
    for my $key (keys %filter) {
        for my $action (map { trim $_ } split ',', $key) {
            unshift(
                @{$self->{filters}->{$action}},
                map { Ridge::ActionFilter->new($_) } _list2array($filter{$key})
            );
        }
    }
}

sub run {
    my ($self, $action, $r, $engine) = @_;
    $action or croak "missing action name as argument";

    if (my $filters = $self->retrieve($action)) {
        for my $filter (@{$filters}) {
            my $result = $filter->run($r, $engine);
            # last unless $result;
            goto FILTER_STOPPED unless $result;
        }
    }
    return 1;

 FILTER_STOPPED:
    {
        if (not $r->goto_view_flag and not $r->res->code) {
            Ridge::Exception::RequestError->throw(code => RC_BAD_REQUEST);
        } else {
            return;
        }
    }
}

sub clone {
    my $self  = shift;
    my $class = ref $self;

    my $cloned = $class->new;
    $cloned->{filters} = +{
        map {
            $_ => [ @{$self->{filters}->{$_}} ]
        } keys %{$self->{filters} || {}}
    };
    return $cloned;
}

1;
