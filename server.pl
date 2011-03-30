#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use Path::Class;
use lib glob 'modules/*/lib';
use lib 'lib';

use Getopt::Long;
use Pod::Usage;
use Plack::Runner;
use UNIVERSAL::require;

my $help    = 0;
my $port    = 3000;
my $env;
my $kyt_prof;

GetOptions(
    'help|?'    => \$help,
    'port|p=s'  => \$port,
    'env|e=s'   => \$env,
    'enable-kyt-prof!' => \$kyt_prof,
);

pod2usage(1) if $help;

$ENV{RIDGE_ENV} = $env if $env;
$ENV{RIDGE_SERVERPL} = 1;


{
    no warnings 'redefine';
    *Plack::Runner::prepare_devel = sub {
        my ($self, $app) = @_;
        $app = $self->apply_middleware($app, 'Lint');
        $app = $self->apply_middleware($app, 'StackTrace');

        push @{$self->{options}}, server_ready => sub {
            my($args) = @_;
            my $name  = $args->{server_software} || ref($args); # $args is $server
            my $host  = $args->{host} || 0;
            my $proto = $args->{proto} || 'http';
            print STDERR "$name: Accepting connections at $proto://$host:$args->{port}/\n";
        };

        $app;
    };
};

if ($kyt_prof) {
    if (Devel::KYTProf->require) {
        Devel::KYTProf->namespace_regex('Hatena');
        Devel::KYTProf->ignore_class_regex(qr{
            Role::CachesMethod |
            Memcached
        }x);
    }
}

my $preload = [qw/Ridge DBIx::MoCo/];

my $runner = Plack::Runner->new;
$runner->parse_options(
    '--server', 'HTTP::Server::Simple',
    '--port', $port || 3007,
#    '--Reload', join(',', glob('modules/*/lib'), 'lib'),
#    '--loader', 'Shotgun',
    '--app', 'script/app.psgi',
    map { "-M$_" } @$preload,
);
$runner->run;

1;

=head1 NAME

server.pl - Ridge Server

=head1 SYNOPSIS

server.pl [options]

 Options:
   -?  --help               display this help and exits
   -p  --port=<port>        port (defaults to 3000)
   -e  --env=<variable>     define $ENV{RIDGE_ENV}

=head1 DESCRIPTION

Run a Ridge server for this application.

=head1 AUTHOR

Naoya Ito, "platform@hatena.ne.jp"

=cut
