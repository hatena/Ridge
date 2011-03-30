#!perl
use strict;
use warnings;

FunctionTest->runtests;

package FunctionTest;
use base qw/Test::Class/;
use Test::More skip_all => 'Function is now obsoleted';
use FindBin::libs;
use Sandbox;

sub process ($) {
    my $url = shift;
    Sandbox->process({ uri  => $url });
}

sub test_functions : Test(3) {
    my $res = process('http://d.hatena.ne.jp/private');
    is $res->code, 403;
    is $res->content, 'Permission Denied';

    is process('http://d.hatena.ne.jp/badreq')->code, 400;
}

sub test_functions_with_exception : Tests {
    my $res = process('http://d.hatena.ne.jp/foo');
    is $res->code, 200;
    is $res->content, 'oops';
}

sub test_no_functions : Test(2) {
    my $res = process('http://d.hatena.ne.jp/hoge');
    is $res->code, 200;
    is $res->content, 'hoge';
}
