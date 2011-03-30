package Ridge::Engine::Basic;

use strict;
use warnings;
use MIME::Base64;
use base qw/Class::Data::Inheritable/;

__PACKAGE__->mk_classdata(qw/basic_password/);

sub basic {
    my ($self, $r) = @_;
    my ($username, $password) = $self->_get_auth_data($r->req);
    ($username || $password) or return $self->_set_basic_handler($r);

    my %pwds = %{$self->basic_password};
    if (scalar keys %pwds) {
        for my $uname (keys %pwds) {
            my $pwd = $pwds{$uname};
            if ($username eq $uname && $password eq $pwd) {
                return 0;
            }
        }
    }
    return $self->_set_basic_handler($r);
}

sub _set_basic_handler {
    my ($self, $r) = @_;
    $r->res->code(401);
    $r->res->content_type('text/plain');
    $r->res->content('Auth Error!');
    $r->res->headers->header('Status' => 'Unauthorized');
    $r->res->headers->header('WWW-Authenticate' => 'Basic realm="auth"');
    return 1;
}

sub _get_auth_data {
    my ($self, $req) = @_;
    my @authdata;
    if ($req->getenv('X-HTTP_AUTHORIZATION')) {
        @authdata = split " ", $req->getenv('X-HTTP_AUTHORIZATION'), 2;
    } elsif($req->getenv('HTTP_AUTHORIZATION'))  {
        @authdata = split " ", $req->getenv('HTTP_AUTHORIZATION'), 2;
    } elsif($req->getenv('Authorization'))  {
        @authdata = split " ", $req->getenv('Authorization'), 2;
    }
    if(scalar(@authdata) && $authdata[0] eq 'Basic') {
       return split ':', decode_base64($authdata[1]);
    }
}

1;
=pod
use Hatena::XXX::Engine -Base;
use base qw/Ridge::Engine::Basic/;

__PACKAGE__->basic_password({
    'myusername' => 'mypassword3',
    'allowusername' => 'passwordddddd',
});

sub default : public {
    my ($self, $r) = @_;
    $self->basic($r) and return;
    1;
}

=cut
