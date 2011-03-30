package Ridge;
use strict;
use warnings;
use base qw/Ridge::Object/;

our $VERSION = 0.10;

use Carp;
use CLASS;
use Class::Trigger;
use Class::Component;
use HTTP::Status;

use Encode;
use Path::Class qw/file dir/;
use UNIVERSAL::require;
use Log::Dispatch;
use Time::HiRes;
use Module::Pluggable;

use Ridge::Config;
use Ridge::Engine::Factory;
use Ridge::Response;
use Ridge::View;
use Ridge::Stash;
use Ridge::Request;
use Ridge::Exceptions;
use Ridge::ActionResult;
use Ridge::Util;
use Ridge::Message::List;
use Ridge::Error::List;
use Ridge::Flash;

use Ridge::URI;
use Ridge::URI::Lite;

CLASS->mk_ro_accessors(qw/request response action_stack/);
CLASS->mk_accessors(qw/view flow stash goto_view_flag/);
CLASS->mk_classdata('config');
CLASS->mk_classdata('logger');
CLASS->mk_classdata('debug'); # obsolute!
CLASS->mk_classdata('loaded'); 

## setting default empty logger
CLASS->logger(Log::Dispatch->new);

*req = \&request;
*res = \&response;

CLASS->load_components(qw/Autocall::InjectMethod DisableDynamicPlugin/);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    for my $plugin (@{$self->class_component_plugins}) {
        $plugin->stash(Ridge::Stash->new);
    }

    bless $self, $class;
}

sub process {
    my $class = shift;
    my $self = $class->_process(@_);
    $self->gc;
    $self->res->finalize;
}

sub test_process {
    my $class = shift;
    return $class->_process(@_);
}

sub _process {
    my ($class, $env, $args) = @_;
    $class->config->param(root => $args->{root}) if $args->{root};

    my $self = $class->new({
        request        => $class->make_request($env),
        response       => $class->make_response,
        view           => Ridge::View->new,
        stash          => Ridge::Stash->new,
        _errors        => Ridge::Error::List->new,
        _messages      => Ridge::Message::List->new,
        action_stack   => [],
        goto_view_flag => 0,
        logger         => $class->logger,
    });
    $self->res->request($self->request);

    $self->logger->info("URI class -> " . ref $self->req->uri);
    $self->logger->info("URI -> " . $self->req->uri->as_string);

    $self->flow($self->req->uri->to_flow);

    for my $plugin (@{$self->class_component_plugins}) {
        $plugin->initialize($self);
    }

    my $engine = Ridge::Engine::Factory->instantiate({
        namespace => $self->config->param('namespace'),
        flow      => $self->flow,
    });

    my $e;
    my $bm_time = [Time::HiRes::gettimeofday]; 
    if (keys %{$self->req->parameters}) {
        $self->logger->info(sprintf 'Params -> {%s}', join ', ', map 
            { $_ . ' => ' . $self->req->param($_) } keys %{$self->req->parameters}
        );
    }
    my $view_start_time;
    eval {
        $self->call_trigger('before_dispatch', $engine);
        $self->dispatch_to_action($engine);
        $view_start_time = [Time::HiRes::gettimeofday];
        $self->forward_to_view;
        $engine->run_after_filter($self);
    };
    if ($e = caught('Ridge::Exception::RequestError')) {
        $e->do_task($self);
    } elsif ($e = caught()) {
        rethrow $e;
    }

    eval {
        $self->call_trigger('after_dispatch', $engine);
    };
    if ($e = caught('Ridge::Exception::RequestError')) {
        $e->do_task($self);
    } elsif ($e = caught()) {
        rethrow $e;
    }

    $self->finalize_header;

    my $second = Time::HiRes::tv_interval($bm_time);
    if (!$ENV{RIDGE_ENV} or $ENV{RIDGE_ENV} ne 'production') {
        $self->logger->info(
            sprintf "Response -> %s, [%s, %s]\n", $second,
            $self->response->code, join(';', $self->response->content_type)
        );
    }
    $self->res->push_header('X-Runtime' => int($second * 1000) . 'ms' );
    $self->res->push_header('X-Ridge-Dispatch' => join('#', ref($engine), ($self->flow->action || 'default'), $self->flow->view || ()));
    if (defined $view_start_time) {
       my $view_second = Time::HiRes::tv_interval($view_start_time);
       $self->res->push_header('X-View-Runtime' => int($view_second * 1000) . 'ms');
       undef $view_start_time;
       undef $view_second;
    }
    undef $bm_time;
    undef $second;
    $self;
}

sub configure {
    my ($class, $args) = @_;
    my $config_class = 'Ridge::Config';

    if ((ref $args and ref $args eq 'HASH' and not $args->{ignore_config}) || !$args) {
        $config_class = join '::', $class, 'Config';
        $config_class->require;
    }

    if ($@ and $@ =~ m/Can\'t locate .*? in \@INC/) {
        $config_class = 'Ridge::Config';
    }

    if ( $class->config ) {
        my $app_config = delete $args->{app_config};
        $class->config->param(%$args);
        if ($app_config) {
            $class->config->app_config($_)->param(%{$app_config->{$_}})
                for keys %$app_config;
        }
    } else {
        my $config = (ref $args and ref $args eq 'HASH')
            ? $config_class->new->setup($args)
            : $config_class->load($args);
        $class->config( $config );
    }

    $class->config->param(namespace => $class);
    $class->setup_logger;
    $class->post_configure;
}

sub post_configure {
    my $class = shift;
    if (my $uri = $class->config->param('URI')) {
        if (ref $uri) {
            if ($uri->{use_lite}) {
                Ridge::URI::Lite->use or die $@;
                $Ridge::Request::PREFERRED_URI = 'Ridge::URI::Lite';
                Ridge::URI::Lite->filter($uri->{filter}) if $uri->{filter};
            } else {
                Ridge::URI->use or die $@;
                Ridge::URI->replace_syntax($uri->{syntax}) if $uri->{syntax};
                Ridge::URI->filter($uri->{filter}) if $uri->{filter};
            }
        } else {
            Ridge::URI->replace_syntax($uri);
        }
    }
    $class->setup_plugins;
}


sub setup_logger {
    my $class = shift;
    my $logger = $class->config->logger;
    Ridge->logger($logger) if $logger;
}

sub setup_plugins {
    my $class = shift;
    if (my $plugins = $class->config->param('plugins')) {
        if (@{$plugins}) {
            $class->logger->info('Loading Plugin(s)... ', join ', ', @{$plugins} );
            ## plugin initialization with hacking Class::Component
            my %plugin_config;
            for (grep { m/^Plugin::/ or m/^\+/ } keys %{$class->config}) {
                if (/^\+(.*)/) {
                    $plugin_config{$1} = $class->config->param($_);
                }
                else {
                    m/^Plugin::(.+)/;
                    $plugin_config{$1} = $class->config->param($_);
                }
            }

            ## hack
            {
                no strict 'refs';
                no warnings 'redefine';
                *{$class . "::class_component_config"} = sub {
                    \%plugin_config;
                };
            }
            $class->load_plugins(@{$plugins});
        }
    }
}

sub make_request {
    my ($class, $env) = @_;
    my $req = Ridge::Request->new($env);
    $req->charset($class->config->param('charset'));
    $req;
}

sub make_response {
    my $class = shift;
    my $res = Ridge::Response->new;
}

sub dispatch_to_action {
    my ($self, $engine, $action, @args) = @_;
    my $res;
    $res = $action ? $engine->_dispatch_to($action, $self, @args)
        : $engine->_dispatch($self, @args);
    $res->next_action($self, $engine) if $res->has_next_action;
}

sub forward_to_view {
    my $self = shift;
    my $res = $self->res;

    if (not $res->is_redirect and !$res->content) {
        my $e;
        eval {
            my $impl = $self->view->impl(
                uc($self->flow->view || 'tt'), $self->config
            );


            if (not $self->view->is_available($impl->type)) {
                $self->logger->info(sprintf 'This page does not have permission to make %s.', $impl->type);
                Ridge::Exception::RequestError->throw(code => RC_NOT_FOUND);
            }

            my $tmplate_name = $impl->use_template ? $self->view->filename || find_template({
                        flow => $self->flow,
                        root => $self->config->param('root')
            })->stringify : '';

            my @msg = ('View -> ' . ref $impl);
            push @msg, sprintf '[%s]', $tmplate_name if $tmplate_name;
            $self->logger->info(join ' ', @msg);

            my $content = $impl->process($self, $tmplate_name);
            $content = Encode::is_utf8($content) ? Encode::encode_utf8($content) : $content;
            $res->content($content);
        };
        if ($e = caught('Ridge::Exception::TemplateNotFound')) {
            $self->logger->info($e->as_string_pretty);
            Ridge::Exception::RequestError->throw(code => RC_NOT_FOUND);
        } elsif ($e = caught()) {
            rethrow $e;
        }
    }
    $res;
}

sub finalize_header {
    my $self = shift;
    my $res = $self->res;

    $res->code(RC_OK) unless defined $res->code;
    $res->charset($self->config->param('charset')) unless $res->charset;
    $res->content_type(
        sprintf "%s; charset=%s",
        $res->content_type || 'text/html',
        $res->charset,
    );

    for ($res->cookies) {
        if (not $_->domain and $self->config->param('cookie_domain')) {
            $_->domain($self->config->param('cookie_domain'));
        }
    }
    {
        use bytes;
        $res->content_length(length($self->res->content || ''));
    }
    $res;
}

sub gc {
    my $self = shift;

    ## cleaning up plugin's stashes since they are lived in closures.
    for my $plugin (@{$self->class_component_plugins}) {
        $plugin->cleanup;
    }

    ## setting core objects to the stash may cause cyclic references.
    $self->stash(undef);
}

## public methods
sub forward {
    my ($self, $action, $args) = @_;
    $self->logger->info('forward to -> ' . $action);
    return Ridge::ActionResult->as(forward => {
        action => $action,
        args   => $args || {},
    });
}

sub forward_to_message {
    my ($self, $name, $text, $args) = @_;
    return Ridge::ActionResult->as(message => {
        name    => $name,
        message => $text || '',
        args    => $args || {},
    });
}

sub follow_method {
    my ($self, $args) = @_;
    my $method = lc $self->req->request_method;
    my $action = $self->flow->action;

    $self->logger->info(' |- follow_method -> ' . $method);

    return Ridge::ActionResult->as(follow => {
        action => (not $action or $action eq 'default')
            ? sprintf "_%s", $method
            : sprintf "_%s_%s", $action, $method,
        args   => $args,
    });
}

sub flash {
    my $self = shift;
    if (not defined $self->{_flash}) {
        my $klass =  $self->app_config->param('flash_storage') || 'Ridge::Flash::Cookie';
        $klass->require or die $@;
        $self->{_flash} = $klass->new;
    }
    my $flash = $self->{_flash};
    $flash->res($self->res);
    $flash->req($self->req);
    return $flash;
}

sub path_to {
    my ($self, @path) = @_;
    my @args = ($self->config->param('root'), @path);
    my $path = dir(@args);
    -d $path ? $path : file(@args);
}

sub app_config {
    my ($self, $env) = @_;
    $env ||= Ridge::Config->ridge_default_env;
    $self->config->app_config($env);
}

sub message {
    my $self = shift;
    $self->{_messages}->add(@_) if @_;
    $self->{_messages};
}

sub error {
    my $self = shift;
    $self->{_errors}->add(@_) if @_;
    $self->{_errors};
}

sub has_error {
    scalar @{$_[0]->{_errors}};
}

sub has_message {
    scalar @{$_[0]->{_messages}};
}

sub goto_view {
    my $self = shift;
    $self->goto_view_flag(1);
    return;
}

1;

__END__

=head1 NAME

Ridge - A light weight web application framework

=head1 AUTHOR

Naoya Ito, E<lt>platform@hatena.ne.jp<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
