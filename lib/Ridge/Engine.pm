package Ridge::Engine;
use strict;
use warnings;
use base qw/Ridge::AttrHandler Ridge::Object/;
use CLASS;
use List::MoreUtils qw/any/;
use UNIVERSAL;
use HTTP::Status;

use Ridge::Util qw/logger/;
use Ridge::Exceptions;
use Ridge::ActionResult;
use Ridge::ActionFilter::Container;

CLASS->mk_classdata(qw/_before_filter/);
CLASS->mk_classdata(qw/_after_filter/);

sub _make_filter_method {
    my ($callpkg, $attr, $append_or_prepend) = @_;
    return sub {
        $callpkg->$attr(Ridge::ActionFilter::Container->new)
            unless $callpkg->$attr;

        my %args = @_;
        for my $key (keys %args) {
            if ($key eq ':all') {
                my $filters = delete $args{$key};
                for my $action ($callpkg->public_actions) {
                    $callpkg->$attr->$append_or_prepend($action => $filters);
                }
            } elsif ($key =~ /^:except (.+)$/) {
                my $filters = delete $args{$key};
                my $except_actions = [ split /\s*,\s*/, $1 ];
                for my $action ($callpkg->public_actions) {
                    next if any { $action eq $_ } @$except_actions;
                    $callpkg->$attr->$append_or_prepend($action => $filters);
                }
            }
        }
        $callpkg->$attr->append(%args);
    };
}

sub import {
    my $class = shift;
    my $callpkg = caller 0;
    if (any { $_ eq '-Base' } @_) {
        no strict 'refs';
        push @{"$callpkg\::ISA"}, $class;

         for my $method (qw/before_filter after_filter/) {
             my $attr = sprintf "_%s", $method;

             my $container = $class->$attr ? $class->$attr->clone : Ridge::ActionFilter::Container->new;
             $callpkg->$attr($container);

             {
                 ## because Module::Referesher on Ridge::Daemon is noisy.
                 no warnings 'redefine';

                 *{"$callpkg\::$method"} = _make_filter_method($callpkg, $attr, 'append');
                 *{"$callpkg\::prepend_$method"} = _make_filter_method($callpkg, $attr, 'prepend');
             }
         }
    }
}

## dispatch automatically without any action name.
sub _dispatch {
    my ($self, $r, @argv) = @_;
    my $action = $r->flow->action;
    $action ||= 'default';
    $action = 'default' if $action and $action =~ m/^_/;

    $r->logger->info(sprintf 'Action -> %s#%s [%s]', 
        ref $self,  $action, $r->request->request_method);
    if ($self->can($action) and not $self->is_public($action)) {
        $r->logger->debug(sprintf 'Action "%s" is not Public', $action);
        Ridge::Exception::RequestError->throw(code => RC_NOT_FOUND);
    }

    my ($e, $res);
    eval {
        $res = $self->_dispatch_to($action, $r, @argv);
    };
    if ($e = caught('Ridge::Exception::NoSuchAction')) {
        $r->logger->info(' |- action fallback to -> default');
        $res = $self->_dispatch_to('default', $r, @argv);
    } elsif ($e = caught()) {
        rethrow $e;
    }
    $res;
}

## dispatch manually with explicitly specified action.
sub _dispatch_to {
    my ($self, $action, $r, @argv) = @_;
    if (not $self->can($action)) {
        Ridge::Exception::NoSuchAction->throw(
            message => sprintf("No such action '%s' on '%s'", $action, ref $self),
            action  => $action,
            engine  => $self
        );
    }

    push @{$r->action_stack}, $action;

    my $continue = 1;
    $continue = $self->_before_filter->run($action, $r, $self) if $self->_before_filter;
    my $res = $self->$action($r, @argv) if $continue;
    # $self->_after_filter->run($action, $r, $self) if $self->_after_filter;

    (ref $res and UNIVERSAL::isa($res, 'Ridge::ActionResult'))
        ? $res
        : Ridge::ActionResult->as('default');
}

sub run_after_filter {
    my ($self, $r) = @_;
    $self->_after_filter or return;
    for my $action (reverse @{$r->action_stack}) {
        $self->_after_filter->run($action, $r, $self);
    }
}

sub default : Public {
    # Do nothing, automatically forwarded to the view.
}

1;
