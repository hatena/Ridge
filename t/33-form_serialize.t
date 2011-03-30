#!perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use HTTP::Request::Common;
use HTTP::Message::PSGI;
use Ridge::Request;

my $req = Ridge::Request->new(
    (POST '/', [
        title => 'foo',
        body  => 'bar',
        age   => [ 20, 30 ],
        xss   => '"<s>',
    ])->to_psgi
);

ok $req->can('serialize');

my $html = $req->serialize;
like $html, qr!<input type="hidden" name="title" value="foo" \/>!;
like $html, qr!<input type="hidden" name="body" value="bar" \/>!;
like $html, qr!<input type="hidden" name="age" value="20" \/>!;
like $html, qr!<input type="hidden" name="age" value="30" \/>!;
like $html, qr!<input type="hidden" name="xss" value="&quot;&lt;s&gt;" \/>!;

$html = $req->serialize(only => [qw/title/]);
like $html, qr!<input type="hidden" name="title" value="foo" \/>!;
unlike $html, qr!<input type="hidden" name="body" value="bar" \/>!;
unlike $html, qr!<input type="hidden" name="age" value="20" \/>!;
unlike $html, qr!<input type="hidden" name="age" value="30" \/>!;

$html = $req->serialize({ only => [qw/title body/] });
like $html, qr!<input type="hidden" name="title" value="foo" \/>!;
like $html, qr!<input type="hidden" name="body" value="bar" \/>!;
unlike $html, qr!<input type="hidden" name="age" value="20" \/>!;
unlike $html, qr!<input type="hidden" name="age" value="30" \/>!;

$html = $req->serialize(exclude => [qw/title body/]);
unlike $html, qr!<input type="hidden" name="title" value="foo" \/>!;
unlike $html, qr!<input type="hidden" name="body" value="bar" \/>!;
like $html, qr!<input type="hidden" name="age" value="20" \/>!;
like $html, qr!<input type="hidden" name="age" value="30" \/>!;
like $html, qr!<input type="hidden" name="xss" value="&quot;&lt;s&gt;" \/>!;

$html = $req->serialize({ exclude => [qw/title body/] });
unlike $html, qr!<input type="hidden" name="title" value="foo" \/>!;
unlike $html, qr!<input type="hidden" name="body" value="bar" \/>!;
like $html, qr!<input type="hidden" name="age" value="20" \/>!;
like $html, qr!<input type="hidden" name="age" value="30" \/>!;
like $html, qr!<input type="hidden" name="xss" value="&quot;&lt;s&gt;" \/>!;
