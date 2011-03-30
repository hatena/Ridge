#!perl
use Test::More qw/no_plan/;
use Ridge::Request;

my $req = Ridge::Request->new({
    HTTP_HOST => 'localhost',
    REQUEST_URI => 'http://localhost/?abcd=123&name=none&value=23',
    QUERY_STRING => 'abcd=123&name=none&value=23',
});

$req->param(-name => 'hoge', -value => 'fuga');
is $req->param('hoge'), 'fuga';

is $req->param('abcd'), 123, 'abcd';

$req->param(abcd => 456);
is $req->param('abcd'), 456, 'set abcd';

$req->param(name => 'MyName');
is $req->param('name'), 'MyName', 'set name';

is $req->param('value'), 23, 'get value';

$req->param(value => 'Value');
is $req->param('value'), 'Value', 'set value';

$req->param(-option => 'Option');
is $req->param('option'), 'Option';

$req->param(-name => 'name1', -value => 'value1');
is $req->param('name1'), 'value1';

is $req->param('name'), 'MyName';
is $req->param('value'), 'Value';

