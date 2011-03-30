#!perl
use strict;
use warnings;
use HTTP::Request;
use HTTP::Message::PSGI;

my $req = HTTP::Request->new(GET => 'http://d.hatena.ne.jp/?mode=foobar&bar=baz');
$req->content_type('text/html');

my $env = $req->to_psgi;
CGITest->runtests;

package CGITest;
use base qw/Test::Class/;
use Test::Most;

use Ridge::Request;
use HTTP::Request::Common;

sub test_setup : Test(setup) {
    my $self = shift;
    $self->{req} = Ridge::Request->new($env);
}

sub test_methods : Tests {
    my $self = shift;
    my $req = $self->{req};

    is $req->param('mode'), 'foobar';
    is $req->param('bar'), 'baz';
    is $req->request_method, 'GET';
    is $req->server_port, 80;
    is $req->server_name, 'd.hatena.ne.jp';
    is $req->path_info, '/';
    is $req->content_type, 'text/html';

    {
        $req->charset('utf8');
        use utf8;
        my $a = 'ああ';
        $req->set_param(foo => $a);
        ok utf8::is_utf8($req->param('foo'));
        is $req->param('foo'), $a;
    };

    {
        $req->charset('utf8');
        use utf8;
        my $a = 'ああ';
        $req->set_param(foo => $a);
        ok utf8::is_utf8($req->param('foo'));
        is $req->param('foo'), $a;
    };
}

sub test_param : Test(6) {
    my $self = shift;
    my $req = $self->{req};

    $req->param(-name => 'simple', -value => 'baz');
    is $req->param('simple'), 'baz';

    $req->param(-name => 'multi', -value => [qw/baz bar/]);
    is scalar $req->param('multi'), 'bar';

    is_deeply [ $req->param('multi') ], [qw/baz bar/];

    $req->param(
        aaa => 'vaa',
        bbb => 'vbb',
        ccc => [qw/vc1 vc2/],
    );

    is_deeply [ $req->param('aaa') ], [qw/vaa/];
    is_deeply [ $req->param('bbb') ], [qw/vbb/];
    is_deeply [ $req->param('ccc') ], [qw/vc1 vc2/];
}

sub test_upload : Test(7) {
    my ($self) = @_;

    my $env = POST('/' =>
        Content_Type => 'form-data',
        Content      => [
            foo => 'bar',
            image1 => [undef, 'foo.jpg', Content_Type => 'image/jpeg', Content => 'this is jpeg'],
        ]
    )->to_psgi;

    my $req = Ridge::Request->new($env);

    cmp_deeply [ $req->param ], bag('foo', 'image1');

    is scalar $req->param('foo'), 'bar';
    is scalar $req->param('image1'), 'foo.jpg';

    my $upload = $req->upload('image1');
    is "$upload", "foo.jpg";
    is $upload->filename, "foo.jpg";
    is $upload->as_string, "foo.jpg";
    is join('', $upload->as_iterate), 'this is jpeg';
}


1;
