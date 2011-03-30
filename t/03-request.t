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
    is $req->uri, 'http://localhost:80/';
    is $req->original_uri, 'http://localhost/';

    is $req->uri->path, '/';
    is $req->original_uri->path, '/';

    $req->uri->path('/foobar');
    is $req->uri->path, '/foobar';
    is $req->original_uri->path, '/';

    $req->original_uri->path('/foobar');
    is $req->original_uri->path, '/';

    is $req->param("POSTDATA"), 'title=%E3%81%AF%E3%81%A6%E3%81%AA&body=Hello%2C+World!!';
}

{
    my $req = Ridge::Request->new(GET('/', 'Authorization' => 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==')->to_psgi);
    is $req->get_header('Authorization'), 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==';
}

{
    my $req = Ridge::Request->new(GET('/?')->to_psgi);
    is $req->uri, "http://localhost:80/?";
}


done_testing;
