#!perl
use strict;
use warnings;
use Test::More qw/no_plan/;

use HTTP::Request::Common;
use HTTP::Message::PSGI;
use Ridge::Request;

my $req = Ridge::Request->new(
    (POST '/', [
        title => '',
        body  => '',
        age   => 20,
    ])->to_psgi
);

ok $req->can('validator');
ok $req->can('form');

$req->form(
    title => [qw/NOT_BLANK/],
    body  => [qw/NOT_BLANK/],
);

ok $req->form->has_error;
ok $req->form->missing('title');
ok $req->form->missing('body');
isa_ok $req->validator, 'FormValidator::Simple';
