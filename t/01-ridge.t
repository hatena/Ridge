#!perl
use strict;
use warnings;

RidgeTest->runtests;

package RidgeTest;
use base qw/Test::Class/;
use Test::More;
use Ridge;

sub setup : Test(setup) {
    my $self = shift;
    $self->{ridge} = Ridge->new;
    $self->{ridge}->configure({
        root       => '/path/to/root',
        app_config => {
            default => {
                uri          => URI->new('http://d.hatena.ne.jp/'),
                service_name => 'Hatena::Diary',
            },
            devel   => {
                uri => URI->new('http://dtest.hatena.ne.jp/'),
            }
        },
    });
}

sub test_instance : Test(2) {
    my $self = shift;
    ok ref $self->{ridge};
    isa_ok $self->{ridge}->config, 'Ridge::Config';
}

sub test_path_to : Test(2) {
    my $self = shift;
    is $self->{ridge}->path_to('templates'), '/path/to/root/templates';
    is $self->{ridge}->path_to('templates', 'index.html'), '/path/to/root/templates/index.html';
}

sub test_config : Tests {
    my $self = shift;
    my $r = $self->{ridge};

    local $ENV{RIDGE_ENV};
    is $r->app_config->param('uri'), 'http://d.hatena.ne.jp/';
    is $r->app_config->param('service_name'), 'Hatena::Diary';

    local $ENV{RIDGE_ENV} = 'devel';
    is $r->app_config->param('uri'), 'http://dtest.hatena.ne.jp/';
    is $r->app_config->param('service_name'), 'Hatena::Diary';
}
