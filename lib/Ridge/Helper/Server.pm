package Ridge::Helper::Server;
use strict;
use warnings;
use base qw/Ridge::Helper/;

sub create {
    my $self = shift;
    $self->render_file('script', 'server.pl');
}

1;

__DATA__
[% h.startperl %]
use strict;
use warnings;

use FindBin;
use Path::Class;
use lib 'lib';
use lib glob 'modules/*/lib';

use Getopt::Long;
use Pod::Usage;
use Plack::Runner;

my $help    = 0;
my $port    = 3000;
my $fast    = 0;
my $verbose = 0;
my $env;
my $reboot;
my $reboot_port;
my $kyt_prof;

GetOptions(
    'help|?'    => \$help,
    'port|p=s'  => \$port,
    'fast|f'    => \$fast,
    'env|e=s'   => \$env,
    'verbose|v' => \$verbose,
    'reboot|r'  => \$reboot,
    'reboot_port|rp=s' => \$reboot_port,
    'enable-kyt-prof' => \$kyt_prof,
);

if ($kyt_prof) {
    if (Devel::KYTProf->require) {
        Devel::KYTProf->namespace_regex('MyApp');
        Devel::KYTProf->ignore_class_regex(qr{
            Role::CachesMethod |
            MyApp::Memcached
        }x);
    }
}

pod2usage(1) if $help;

local $ENV{RIDGE_ENV} = $env if $env;

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

my $runner = Plack::Runner->new;
$runner->parse_options(
    '--server', 'HTTP::Server::Simple',
    '--port', $port,
    '--Reload', join(',', glob('modules/*/lib'), 'lib'),
    '--app', 'script/app.psgi',
);
$runner->run;

