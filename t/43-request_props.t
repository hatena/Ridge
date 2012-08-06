#!perl
use Test::More qw/no_plan/;
use Test::Differences;
use Ridge::Request;

{
    package test::Request;

    sub new {
        my $class = shift;
        return bless {@_}, $class;
    }

    sub getenv {
        my $self = shift;
        return $self->{env}->{$_[0]};
    }

    sub param {
        my ($self, $name) = @_;
        return $self->{param}->{$name};
    }

    sub request_method {
        my ($self) = @_;
        return $self->getenv('REQUEST_METHOD');
    }

    sub user_agent {
        my ($self) = @_;
        return $self->getenv('HTTP_USER_AGENT');
    }

    *server_name = \&Ridge::Request::server_name;
    *getenv = \&Ridge::Request::getenv;
    *is_tls = \&Ridge::Request::is_tls;
    *is_idempotent = \&Ridge::Request::is_idempotent;
    *epoch_param = \&Ridge::Request::epoch_param;
    *address = \&Ridge::Request::address;
    *browser = \&Ridge::Request::browser;
}

{
    for (
        {result => 'unknown'},
        {addr => '192.168.1.1', result => '192.168.1.1'},
        {name => 'localhost', result => 'localhost'},
        {addr => '192.168.11.2', result => 'localhost', result => '192.168.11.2'},
    ) {
        my $req = test::Request->new(
            env => {
                SERVER_NAME => $_->{name},
                SERVER_ADDR => $_->{addr},
            },
        );

        is $req->server_name, $_->{result};
    }
}

{
    for (
        {result => undef, idempotent => 0},
        {method => 'get', result => 'get', idempotent => 0},
        {method => 'GET', result => 'GET', idempotent => 1},
        {method => 'HEAD', result => 'HEAD', idempotent => 1},
        {method => 'POST', result => 'POST', idempotent => 0},
        {method => 'PUT', result => 'PUT', idempotent => 0},
    ) {
        my $req = test::Request->new(
            env => {
                REQUEST_METHOD => $_->{method},
            },
        );

        is $req->request_method, $_->{result};
        is !!$req->is_idempotent, !!$_->{idempotent};
    }
}

{
    my $req = test::Request->new(env => {});
    ok !$req->is_tls;
    
    $req = test::Request->new(env => {HTTPS => ''});
    ok !$req->is_tls;
    
    $req = test::Request->new(env => {HTTPS => 'on'});
    ok $req->is_tls;
    
    $req = test::Request->new(env => {HTTPS => 'ON'});
    ok $req->is_tls;
}

# For compat
{
    local $ENV{HTTPS} = undef;
    my $req = test::Request->new;
    ok !$req->is_tls;
    
    local $ENV{HTTPS} = '';
    $req = test::Request->new;
    ok !$req->is_tls;
    
    local $ENV{HTTPS} = 'on';
    $req = test::Request->new;
    ok $req->is_tls;
    
    local $ENV{HTTPS} = 'ON';
    $req = test::Request->new;
    ok $req->is_tls;
}

{
    my $req = test::Request->new(
        param => {
            #a
            b => 0,
            c => 13233,
            d => '',
            e => 'abc',
            f => '100yen',
        },
    );
    is scalar $req->epoch_param('a'), undef;
    is scalar $req->epoch_param('b').'', '1970-01-01T00:00:00';
    is scalar $req->epoch_param('c').'', '1970-01-01T03:40:33';
    is scalar $req->epoch_param('d'), undef;
    is scalar $req->epoch_param('e'), undef;
    is scalar $req->epoch_param('f'), undef;

    eq_or_diff [$req->epoch_param('a')], [];
    eq_or_diff [map { $_.'' } $req->epoch_param('b')], ['1970-01-01T00:00:00'];
    eq_or_diff [map { $_.'' } $req->epoch_param('c')], ['1970-01-01T03:40:33'];
    eq_or_diff [$req->epoch_param('d')], [];
    eq_or_diff [$req->epoch_param('e')], [];
    eq_or_diff [$req->epoch_param('f')], [];
}

for (
    ['192.168.0.1,123.4.5.6' => '123.4.5.6'],
    ['123.4.5.6,192.168.0.1' => '123.4.5.6'],
    ['123.4.5.6,127.0.0.1' => '123.4.5.6'],
    ['123.4.5.6,::1' => '123.4.5.6'],
) {
    my $req = test::Request->new(env => {HTTP_X_FORWARDED_FOR => $_->[0]});
    is $req->address, $_->[1];
}

{
    package test::Ridge::Browser;
    use base qw/Ridge::Browser/;
    $INC{'test/Ridge/Browser.pm'} = __FILE__; # hack for UNIVERSAL::require
}

{
    my $req = test::Request->new;
    isa_ok $req->browser, 'Ridge::Browser';

    local $Ridge::Request::PREFERRED_BROWSER = 'test::Ridge::Browser';
    $req = test::Request->new;
    isa_ok $req->browser, 'test::Ridge::Browser';
}
