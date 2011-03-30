#!perl
use strict;
use warnings;

ResponseTest->runtests;

package ResponseTest;
use base qw/Test::Class/;
use Test::More;

use Test::Exception;
use Ridge::Response;

sub test_instance : Test(1) {
    my $res = Ridge::Response->new;
    isa_ok $res, 'Ridge::Response';
}

sub test_headers : Test(1) {
    my $res = Ridge::Response->new;
    isa_ok $res->headers, 'HTTP::Headers';
}

sub test_redirect : Test(2) {
    my $res = Ridge::Response->new;
    $res->redirect('http://d.hatena.ne.jp/naoya/');
    is $res->code, 302;

    $res->redirect_permanently('http://foo.bar.baz');
    is $res->code, 301;
}

sub test_redirect_newline : Test(4) {
    my $res = Ridge::Response->new;
    $res->redirect('http://d.hatena.ne.jp/naoya/'."\x0D\x0Aevil");
    is $res->code, 302;
    is $res->header('Location'), q<http://d.hatena.ne.jp/naoya/evil>;

    $res->redirect_permanently('http://foo.bar.baz'."\x0D\x0Aevil");
    is $res->code, 301;
    is $res->header('Location'), q<http://foo.bar.bazevil>;
}

sub test_redirect_http : Tests {
    throws_ok {
        my $res = Ridge::Response->new;
        $res->redirect('data:,foobar');
    } qr/redirect uri must be http/;

    throws_ok {
        my $res = Ridge::Response->new;
        $res->redirect('javascript:alert("")');
    } qr/redirect uri must be http/;

    throws_ok {
        my $res = Ridge::Response->new;
        $res->redirect_permanently('data:,foobar');
    } qr/redirect uri must be http/;

    throws_ok {
        my $res = Ridge::Response->new;
        $res->redirect_permanently('javascript:alert("")');
    } qr/redirect uri must be http/;

    lives_ok {
        my $res = Ridge::Response->new;
        $res->redirect('/index');
    };

    lives_ok {
        my $res = Ridge::Response->new;
        $res->redirect_permanently('/index');
    };
}

sub test_content_as_text : Test(2) {
    my $res = Ridge::Response->new;
    my $ret = $res->content_as_text('Hello, World');
    is $res->content, 'Hello, World';
    is $res->content_type, 'text/plain';
}

sub test_content_type : Test(3) {
    my $res = Ridge::Response->new;
    $res->content_type('text/html');
    is $res->content_type, 'text/html';

    $res->header('Content-Type' => 'text/plain; charset=utf-8');
    is $res->content_type, 'text/plain; charset=utf-8';
    is_deeply [ $res->content_type ], [ 'text/plain; charset=utf-8' ];
}


sub test_content : Test(1) {
    my $res = Ridge::Response->new;
    $res->content_type('text/html');
    $res->content('0');

    is $res->content, '0';
}

1;
