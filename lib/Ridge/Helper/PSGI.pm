package Ridge::Helper::PSGI;
use strict;
use warnings;
use base qw/Ridge::Helper/;

sub create {
    my $self = shift;
    $self->render_file('script', 'app.psgi');
}

1;

__DATA__
# vim:set ft=perl:
use strict;
use warnings;
use lib glob 'modules/*/lib';
use lib 'lib';


use UNIVERSAL::require;
use Path::Class;
use Plack::Builder;
use Cache::MemoryCache;

my $namespace = '[% h.namespace %]';
$namespace->use or die $@;

my $root = file(__FILE__)->parent->parent;

$ENV{GATEWAY_INTERFACE} = 1; ### disable plack's accesslog
$ENV{PLACK_ENV} = ($ENV{RIDGE_ENV} =~ /production|staging/) ? 'production' : 'development';

builder {
    unless ($ENV{PLACK_ENV} eq 'production') {
        enable "Plack::Middleware::Debug";
        enable "Plack::Middleware::Static",
            path => qr{^/(images|js|css)/},
            root => $root->subdir('static');
    }

    enable "Plack::Middleware::ReverseProxy";

    sub {
        my $env = shift;
        $namespace->process($env, {
            root => $root,
        });
    }
};

