#!perl
use strict;
use warnings;

ExceptionsTest->runtests;

package ExceptionsTest;
use base qw/Test::Class/;

use Test::More;
use Ridge::Exceptions;
use Class::Inspector;
use Exception::Class;

sub test_template_not_found : Test(3) {
    ok (Class::Inspector->loaded('Ridge::Exception::TemplateNotFound'));
    my $e;
    eval {
        Ridge::Exception::TemplateNotFound->throw(
            error    => 'file not found',
        );
    };
    ok $e = Exception::Class->caught('Ridge::Exception::TemplateNotFound');
    ok $e->isa('Ridge::Exception::TemplateNotFound');
}

sub test_request_error : Test(3) {
    ok (Class::Inspector->loaded('Ridge::Exception::RequestError'));
    my $e;
    eval {
        Ridge::Exception::RequestError->throw(code => 404);
    };
    ok $e = Exception::Class->caught('Ridge::Exception::RequestError');
    ok $e->isa('Ridge::Exception');
}

1;

