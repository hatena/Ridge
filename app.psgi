# vim:set ft=perl:
use strict;
use warnings;
use Path::Class;

my $root;
BEGIN {
    $root = file(__FILE__)->parent->parent->absolute;
    unshift @INC, "$root/lib", glob "$root/modules/*/lib";
}

use UNIVERSAL::require;
use Plack::Builder;

my $namespace = $ENV{RIDGE_NAMESPACE};

builder {
    # production environment
    if ($ENV{SERVER_STATUS_CLASS}) {
        open my $fh, ">>", "/var/log/app/access_log" or die "cannot load log file: $!";
        select $fh; $|++; select STDOUT;
        enable 'Plack::Middleware::AccessLog', logger => sub { print { $fh } @_ };

        enable "Plack::Middleware::ServerStatus";
    }

    if ($ENV{RIDGE_SERVERPL}) {
        enable "Refresh", cooldown => 3;
        enable "Plack::Middleware::Debug";
        enable "Plack::Middleware::Static",
            path => qr{^/(images|js|css)/},
            root => $root->subdir('static');
    }

    enable "Plack::Middleware::ReverseProxy";

    sub {
        my $env = shift;
        $namespace->use or die $@;
        $namespace->process($env, {
            root => $root,
        });
    }
};

