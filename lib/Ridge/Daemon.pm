package Ridge::Daemon;
use strict;
use warnings;

my $with_epoll;

BEGIN {
    use UNIVERSAL::require;
    use POE qw(
        Sugar::Args
        Wheel::SocketFactory
        Wheel::ReadWrite
        Filter::Stream
        Filter::HTTPD
    );
    if (Sys::Syscall->require && Sys::Syscall::epoll_defined() && POE::Loop::Epoll->require) {
        POE::Loop::Epoll->import;
        $with_epoll = 1;
    }
}

use CLASS;
use Class::Trigger;
use File::MimeInfo qw/globs/;
use HTTP::Request::AsCGI;
use HTTP::Status;
use IO::Handle;
use Module::Refresh;
use Path::Class qw/dir file/;
use Path::Class qw/file/;
use Socket;

use Ridge;
use Ridge::Exception;
use Ridge::Util qw/logger/;
use Ridge::Daemon::Connection;

sub msg ($) {
    logger->info(shift);
}

our $VERSION = 0.01;

sub run {
    my ($class, $namespace, $args) = @_;

    $ENV{RIDGE_DEBUG} = !$ENV{HARNESS_ACTIVE};

    $namespace->require or die $@;
    $namespace->debug(1) if $ENV{RIDGE_DEBUG};
    $namespace->import;
    $namespace->debug(0) if $args->{fast};

    msg "Server can be watching connections by epoll(4), good." if $with_epoll;
    msg "Server is now launched as fast mode." if $args->{fast};
    msg "Server is now launched as debug mode." if $namespace->debug;

    POE::Session->create(
        inline_states => {
            _start => \&server_start,
        },
        package_states => [
            'Ridge::Daemon' => [qw(
                server_accepted
                server_error
                client_input
                client_close
                client_error
                client_flushed)
            ],
        ],
        heap => {
            root       => dir($args->{root})->absolute,
            port       => $args->{port},
            namespace  => $namespace,
            fast       => $args->{fast} ? 1 : 0,
            verbose    => $args->{verbose} ? 1 : 0,
        },
    );

    if ($namespace->debug) {
        POE::Session->create(
            inline_states => {
                _start => sub {
                    my $poe = sweet_args;
                    $poe->kernel->alias_set('debug_thread');
                },
                show_debug => \&show_debug,
            }
        );

        my $watch_defs = $args->{watch_defs} || [];
        $_->root($args->{root}) for @$watch_defs;

        POE::Session->create(
            inline_states => {
                _start => sub {
                    my $poe = sweet_args;
                    $poe->kernel->alias_set('watcher_thread');

                    Ridge::Daemon::Watcher->require or die $@;
                    $poe->heap->{watcher} = Ridge::Daemon::Watcher->new({
                        root             => $args->{root},
                        directory        => dir($args->{root}, 'lib'),
                        defs             => $watch_defs,
                    });
                    $poe->kernel->yield('bind') if $args->{reboot_port};
                    $poe->kernel->yield('watch');
                },
                bind   => \&watcher_bind,
                watch  => \&mtime_watch,
                reboot => \&daemon_reboot,

                ## reboot server
                server_accepted => \&reboot_server_accepted,
                server_error    => \&reboot_server_error,
                client_input    => \&reboot_client_input,
                client_flushed  => \&reboot_client_flushed,
                client_error    => \&reboot_client_error,
            },
            heap => {
                port             => $args->{port},
                reboot_port      => $args->{reboot_port},
                reboot_on_reload => $args->{reboot_on_reload} ? 1 : 0,
            }
        );
    }

    POE::Kernel->sig(INT => sub { POE::Kernel->stop });
    POE::Kernel->run;
}

sub server_start {
    my $poe = sweet_args;
    $poe->kernel->alias_set('main_thread');
    my $port = $poe->heap->{port};
    $poe->heap->{server} = POE::Wheel::SocketFactory->new(
        BindAddress  => INADDR_ANY,
        BindPort     => $port,
        SuccessEvent => 'server_accepted',
        FailureEvent => 'server_error',
        Reuse        => 'on',
    );
    msg "Server bind to port $port, ready to accept a new connection.";
}

sub server_accepted {
    my $poe = sweet_args;
    my $con = Ridge::Daemon::Connection->new;
    $con->wheel(POE::Wheel::ReadWrite->new(
        Handle       => $poe->args->[0],
        InputEvent   => 'client_input',
        FlushedEvent => 'client_flushed',
        ErrorEvent   => 'client_error',
        Filter       => POE::Filter::HTTPD->new,
    ));
    $poe->heap->{connection}->{$con->id} = $con;
}

# Latest version of POE::Filter::HTTPD does not have FINISH.
my $HttpdPut = POE::Filter::HTTPD->can('FINISH')
    ? sub { my $self = shift; $self->[POE::Filter::HTTPD::FINISH()]--; @_ }
    : sub { my $self = shift; @_ };

sub client_input {
    my $poe = sweet_args;
    my $req = $poe->args->[0];
    my $con = $poe->heap->{connection}->{$poe->args->[1]};

    my $vars = {
        root      => $poe->heap->{root},
        namespace => $poe->heap->{namespace},
        port      => $poe->heap->{port},
    };

    my $is_static;
    my $res = serve_static($req, $vars);
    $res ? do { ++$is_static } : do { $res = serve_dynamic($req, $vars) };
 
    $res->protocol('HTTP/1.0'); # yet
    $res->request($req);
    $res->date(time);
    $res->push_header(Server => sprintf("%s/%s", CLASS, CLASS->VERSION));
    $con->res($res);

    ## Handle Keep-Alive
    my $con_h = $req->header('Connection') || '';
    if ($con_h =~ m/keep-alive/i) {
        $res->header(Connection => 'keep-alive');
        $res->header('Keep-Alive' => 'timeout=10');
    }

    if ($con_h =~ /close/i) {
        $res->header('Connection' => 'close');
    }

    if ($req->protocol eq 'HTTP/1.1' and $con_h !~ /close/i) {
        $con->keepalive(1);
    }

    if ($req->protocol ne 'HTTP/1.1' and $con_h =~ /keep-alive/i) {
        $con->keepalive(1);
    }

    if ($is_static) {
        $con->keepalive ? $con->flush_header : $con->wheel->put($res);
        if (not $poe->heap->{fast} and $poe->heap->{verbose}) {
            $poe->kernel->post(debug_thread => show_debug => $res)
        }
    } else {
        $con->flush;
        $poe->kernel->post(debug_thread => show_debug => $res)
            unless $poe->heap->{fast};
    }
}

sub client_flushed {
    my $poe = sweet_args;
    my $con = $poe->heap->{connection}->{$poe->args->[0]};

    $con->flush_outbuf if $con->outbuf;
    $con->keepalive 
        ? do { $poe->kernel->delay(client_close => 10 => $con->id); $con->keepalive(0) }
        : $poe->kernel->yield(client_close => $con->id);
}

sub client_close {
    my $poe = sweet_args;
    delete $poe->heap->{connection}->{$poe->args->[0]};
}

sub client_error {
    my $poe = sweet_args;
#     msg(
#         sprintf 'client error: operation \'%s\' failed: %s (%s)',
#         $poe->args->[0],
#         $poe->args->[2],
#         $poe->args->[1],
#     );
    my $id = $poe->args->[3];
    $poe->kernel->yield(client_close => $id);
}

sub server_error {
    my $poe = sweet_args;
    msg(
        sprintf 'server error: operation \'%s\' failed: %s (%s)',
        $poe->args->[0],
        $poe->args->[2],
        $poe->args->[1],
    );
    $poe->kernel->stop;
}

sub serve_static {
    my ($request, $args) = @_;
    my $config = $args->{namespace}->config;
    my $root = $args->{root};
    my $port = $args->{port};
    my $static_path = join('|', @{$config->{static_path}}) if $config->{static_path};

    if ($request->uri->path =~ m!(?:$static_path)!) {
        my $response = Ridge::Response->new;

        local $URI::ABS_REMOTE_LEADING_DOTS  = 1;
        my $path = file($root, $request->uri->path)->relative($root);
        my $file = file($root, 'static', URI->new_abs($path, "http://localhost:$port/")->path);

        if (my $stat = $file->stat) {
            if (-d $file) {
                my $content = '403 Forbidden';
                $response->content($content);
                $response->content_length(length $content);
                $response->content_type('text/plain');
                $response->code(RC_FORBIDDEN);
                return $response;
            }

            if (my $ims = $request->headers->header('If-Modified-Since')) {
                $ims =~ s/;.*//; # for IE
                if (HTTP::Date::str2time($ims) == $stat->mtime ) {
                    $response->code(RC_NOT_MODIFIED);
                    $response->headers->remove_content_headers;
                    $response->headers->remove_header("Content-Length");
                    $response->content('');
                    $response->content_length(0);
                    return $response;
                }
            }

            my $content = $file->slurp;
            my $type = globs($file) || 'application/octet-stream';

            $response->headers->content_type($type);
            $response->headers->content_length($stat->size);
            $response->headers->last_modified($stat->mtime);
            $response->code(RC_OK);
            $response->content($content);
            return $response;
        } else {
            my $content = '404 Not Found';
            $response->content($content);
            $response->content_length(length $content);
            $response->content_type('text/plain');
            $response->code(RC_NOT_FOUND);
            return $response;
        }
    }
    return;
}

sub serve_dynamic {
    my ($req, $args) = @_;
    my $res;
    {
        my $c = HTTP::Request::AsCGI->new(
            $req,
            RIDGE_ENV   => $ENV{RIDGE_ENV} || 'default',
            RIDGE_DEBUG => $ENV{RIDGE_DEBUG} || '',
        )->setup;
        eval {
            $res = $args->{namespace}->process({
                root => $args->{root}
            });
        };
        if (my $e = Ridge::Exception->caught) {
            logger->error($e->as_string_pretty);
            $res = $e->as_response;
        }
    }
    $res;
}

sub show_debug {
    # obsolute
    my $poe = sweet_args;
    my $res = $poe->args->[0];
}

sub mtime_watch {
    my $poe = sweet_args;
    my $watcher = $poe->heap->{watcher};

    if (my @changes = $watcher->watch) {
        if ($poe->heap->{reboot_on_reload}) {
            $poe->kernel->yield(reboot => \@changes);
        } else {
            my $ref = Module::Refresh->new;
            for (@changes) {
                if (/\.pm$/) {
                    $ref->refresh_module($_);
                    msg sprintf 'proccess %d reloading %s', $$, file($_)->relative($poe->heap->{root});
                } else {
                    my $file = file($_)->relative($poe->heap->{root});
                    for my $def (@{$watcher->defs or []}) {
                        $def->process_onupdate($file);
                    }
                }
            }
        }
    }

    $poe->kernel->delay(watch => 1);
}

sub daemon_reboot {
    my $poe = sweet_args;
    my @changes = @{$poe->args->[0] || []};

    if (@changes) {
        my $files = join ', ', map { file($_)->basename } @changes;
        STDERR->printf("File(s) \"%s\" modified, restarting the server...\n\n", $files);
    } else {
        STDERR->printf("Accepting the reboot request, restarting the server...\n\n")
    }

    $SIG{CHLD} = 'DEFAULT';
    wait;

    my $port = $poe->heap->{port};
    my $rp   = $poe->heap->{reboot_port};
    my $exec = $^X . ' "' . $0 . '" ' . "-p $port";
    $exec = join (' ', $exec, '-r') if $poe->heap->{reboot_on_reload};
    $exec = join (' ', $exec, sprintf('-rp=%d', $rp)) if $rp;
    exec $exec;

    exit;
}

sub watcher_bind {
    my $poe = sweet_args;
    $poe->heap->{reboot_server} = POE::Wheel::SocketFactory->new(
        BindAddress  => INADDR_ANY,
        BindPort     => $poe->heap->{reboot_port},
        SuccessEvent => 'server_accepted',
        FailureEvent => 'server_error',
        Reuse        => 'on',
    );
    msg sprintf 'Reboot server bind to port %d, ready to accept a rebooting request. ', $poe->heap->{reboot_port};
}

sub reboot_server_accepted {
    my $poe = sweet_args;
    my $wheel = POE::Wheel::ReadWrite->new(
        Handle       => $poe->args->[0],
        InputEvent   => 'client_input',
        FlushedEvent => 'client_flushed',
        ErrorEvent   => 'client_error',
        Filter       => POE::Filter::HTTPD->new,
    );
    $poe->heap->{reboot_client}->{$wheel->ID} = $wheel;
}

sub reboot_server_error {
    my $poe = sweet_args;
    msg(
        sprintf 'reboot server error: operation \'%s\' failed: %s (%s)',
        $poe->args->[0],
        $poe->args->[2],
        $poe->args->[1],
    );
    $poe->kernel->stop;
}

sub reboot_client_input {
    my $poe = sweet_args;
    my $req = $poe->args->[0];

    my $res = HTTP::Response->new;
    $res->content_type('text/plain');
    $res->content_length(1);
    $res->content('1');

    $poe->heap->{reboot_client}->{$poe->args->[1]}->put($res);
}

sub reboot_client_flushed {
    my $poe = sweet_args;

    ## close connection
    delete $poe->heap->{reboot_client}->{$poe->args->[0]};
    $poe->kernel->yield('reboot');
}

sub reboot_client_error {
}

1;
