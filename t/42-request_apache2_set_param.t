#!perl
use Test::More qw/no_plan/;
use Ridge::Request;
my $req = Ridge::Request->new({
    REQUEST_URI => '/?abcd=123&name=none&value=23',
    QUERY_STRING => 'abcd=123&name=none&value=23',
});

is $req->param('abcd'), 123;

$req->set_param(abcd => 456);
is $req->param('abcd'), 456;

$req->set_param(name => 'MyName');
is $req->param('name'), 'MyName';

is $req->param('value'), 23;

$req->set_param(value => 'Value');
is $req->param('value'), 'Value';

$req->set_param(-option => 'Option');
is $req->param('-option'), 'Option';

$req->set_param(-name => 'name1', -value => 'value1');
is $req->param('-name'), 'name1';
is $req->param('name'), 'MyName';
is $req->param('-value'), undef;

$req->set_param(multi => [qw/foo bar baz/]);
is_deeply [ $req->param('multi') ], [qw/foo bar baz/];

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
