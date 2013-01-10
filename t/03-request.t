#!perl
use strict;
use warnings;

use Test::Most;

use HTTP::Request::Common;
use HTTP::Message::PSGI;
use Ridge::Request;

{
    my $req = Ridge::Request->new(
        (POST '/', [
        title => "はてな",
        body  => 'Hello, World!!',
        ])->to_psgi
    );

    isa_ok $req->uri, 'Ridge::URI';
    isa_ok $req->escaped_uri, 'URI';
    isa_ok $req->original_uri, 'URI';

    is $req->uri, 'http://localhost:80/';
    is $req->escaped_uri, 'http://localhost/';
    is $req->original_uri, 'http://localhost/';

    is $req->uri->path, '/';
    is $req->escaped_uri->path, '/';
    is $req->original_uri->path, '/';

    $req->uri->path('/foobar');
    is $req->uri->path, '/foobar';
    is $req->escaped_uri->path, '/';
    is $req->original_uri->path, '/';

    $req->original_uri->path('/foobar');
    is $req->uri->path, '/foobar';
    is $req->escaped_uri->path, '/';
    is $req->original_uri->path, '/';

    $req->escaped_uri->path('/foobar');
    is $req->uri->path, '/foobar';
    is $req->escaped_uri->path, '/';
    is $req->original_uri->path, '/';

    is $req->param("POSTDATA"), 'title=%E3%81%AF%E3%81%A6%E3%81%AA&body=Hello%2C+World!!';
}

{
    my $req = Ridge::Request->new(GET('/', 'Authorization' => 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==')->to_psgi);
    is $req->header('Authorization'), 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==';
}

{
    my $req = Ridge::Request->new(GET('/?')->to_psgi);
    is $req->uri, "http://localhost:80/?";
}

{
    my $req = Ridge::Request->new(GET('/foo:bar')->to_psgi);
    is $req->uri, "http://localhost:80/foo:bar";
    require Plack;
    is $req->escaped_uri, (Plack->VERSION >= 1.0002)
                          ? "http://localhost/foo:bar"
                          : "http://localhost/foo%3Abar";
    is $req->original_uri, "http://localhost/foo:bar";
}


done_testing;
