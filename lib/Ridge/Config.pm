package Ridge::Config;
use strict;
use warnings;
use base qw/Ridge::Thing/;
use Ridge::Config::App;

use Path::Class qw/file dir/;
use FindBin;
use YAML::Syck;
use Carp;
use Data::Dumper;
use File::Basename qw/dirname basename/;
use Class::Inspector;
use Log::Dispatch::Configurator::YAML;
use Log::Dispatch::Config;

__PACKAGE__->mk_classdata( 'config_path' );
__PACKAGE__->mk_classdata( '__config' );

sub load {
    my ($class, $yaml) = @_;
    $yaml ||= $class->config_path;
    $yaml = file($FindBin::Bin, '..', $yaml || 'config.yml') if not $yaml or not -f $yaml;

    my $self = $class->new;
    $self->install($class->__config) if $class->__config;
    $self->install(YAML::Syck::LoadFile($yaml)) if -e $yaml;
    $self;
}

sub setup {
    my ( $proto, $config ) = @_;
    my $class = ref $proto || $proto;
    $config ||= $class->__config;

    my $super = $class->SUPER::new;
    $super->install($super->__config) if $super->can('__config');
    $super->install($config);
    $class->__config($super->to_hash);

    $super;
}

sub install {
    my ($self, $data) = @_;
    while (my ($key, $value) = each %$data) {
        $value =~ s/\$FindBin::Bin/$FindBin::Bin/g;
        if ($key eq 'app_config') {
            while (my ($app_key, $app_values) = each %$value) {
                $self->app_config($app_key)->param(%{$app_values});
            }
            while (my ($app_key, $app_values) = each %$value) {
                my $ac = $self->app_config($app_key);
                if (my $parent = $ac->param('__parent__')) {
                    unless ($ac->__parent_accessor__) {
                        $ac->__parent_accessor__($self->app_config($parent));
                    }
                }
            }
        } elsif ($key eq 'root') {
            $self->param(root => dir($value));
        } else {
            $self->param($key => $value);
        }
    }
    $self;
}

sub dump {
    return Data::Dumper::Dumper(shift->to_hash);
}

sub app_config {
    my ($self, $env) = @_;
    $env ||= $self->ridge_default_env;

    if ($env eq 'default') {
        $self->{app_config}->{default} ||= Ridge::Thing->new;
    } else {
        if (my $app_config = $self->{app_config}->{$env}) {
            return $app_config;
        } else {
            return $self->{app_config}->{$env} = Ridge::Config::App->new({
                default => $self->app_config('default'),
                env     => $env,
            });
        }
    }
}

sub ridge_default_env {
    return $ENV{RIDGE_ENV} || 'default';
}

# return Log::Dispatch instance
sub logger {
    my $self = shift;

    my $logger = $self->app_config->param('logger');
    return $logger ? $logger : $self->logger_from_yaml;
}

sub logger_from_yaml {
    my $self = shift;

    my $ridge_env = $self->ridge_default_env;
    my $yaml = file($self->find_root, 'config', 'logger',  $ridge_env . '.yml');
    if (-e $yaml) {
        eval {
            my $config = Log::Dispatch::Configurator::YAML->new($yaml);
            Log::Dispatch::Config->configure($config);
        }; 
        if ($@) {
            return;
        } else {
            return Log::Dispatch::Config->instance;
        }
    } else {
        return;
    }
}

sub find_root {
    my $class = ref $_[0] ? ref shift : shift;
    my $d= dir(dirname(Class::Inspector->resolved_filename($class)));
    _find_libdir($d)->parent;
}

sub _find_libdir {
    my $d = shift;
    (basename($d) eq 'lib' or $d eq '/') ? $d : _find_libdir($d->parent);
};

sub _init {
    my $self = shift;
    $self->param(charset => 'utf-8') unless $self->param('charset');
}

1;
