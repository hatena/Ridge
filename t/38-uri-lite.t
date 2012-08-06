use strict;
use warnings;

use Test::Base;
use URI::Escape;

use Ridge::URI::Lite;

URITest->runtests(+ 1 * blocks);

sub parse {
    my $uri = Ridge::URI::Lite->new($_[0]);
    return {
        (map { $_ => $uri->$_ || '' } qw/host port host_port scheme path path_segments action view root/),
    }
}

run_is_deeply;

package URITest;
use base qw/Test::Class/;
use Test::More;
use Ridge::URI;

sub test_instance : Test(3) {
    my $uri = Ridge::URI::Lite->new('http://d.hatena.ne.jp/naoya/');
    isa_ok $uri, 'Ridge::URI::Lite';
    is $uri->host, 'd.hatena.ne.jp';
}

sub test_param : Test(2) {
    my $uri = Ridge::URI::Lite->new('http://d.hatena.ne.jp/naoya/');
    $uri->param(tag => '0');
    is $uri->param('tag'), '0';
    $uri->param(tag => undef);
    is $uri->param('tag'), undef;
}

sub test_query_keywords_none : Test(1) {
    my $uri = Ridge::URI::Lite->new('http://foo/bar?abc=def&xyz=aaa');
    is $uri->query_keywords, undef;
}

sub test_query_keywords_values : Test(1) {
    my $uri = Ridge::URI::Lite->new('http://foo/bar?abc+def&xyz+aaa');
    is_deeply [$uri->query_keywords], ['abc', 'def&xyz', 'aaa'];
}

# sub test_multiple_forwarded_host : Test(3) {
#     my $uri = Ridge::URI::Lite->new('http://d.hatena.ne.jp%2C%20b.hatena.ne.jp/naoya/');
#     isa_ok $uri, 'URI';
#     isa_ok $uri, 'Ridge::URI::Lite';
#     is $uri->host, 'd.hatena.ne.jp';
# }

__END__

=== /
--- input parse
http://d.hatena.ne.jp/
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    port   => 80,
    host_port => 'd.hatena.ne.jp:80',
    path   => '/',
    path_segments => [''],
    action => '',
    view   => '',
    root   => 'http://d.hatena.ne.jp/',
}

=== /entries
--- input parse
http://d.hatena.ne.jp/entries
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    port   => 80,
    host_port => 'd.hatena.ne.jp:80',
    path   => '/entries',
    path_segments => ['entries'],
    action => '',
    view   => '',
    root   => 'http://d.hatena.ne.jp/',
}

=== /entries.rss
--- SKIP
--- input parse
http://d.hatena.ne.jp/entries.rss
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    port   => 80,
    host_port => 'd.hatena.ne.jp:80',
    path   => '/entries.rss',
    path_segments => ['entries'],
    action => '',
    view   => 'rss',
    root   => 'http://d.hatena.ne.jp/',
}

=== /entries.jsons
--- input parse
http://d.hatena.ne.jp/entries.jsons
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    port   => 80,
    host_port => 'd.hatena.ne.jp:80',
    path   => '/entries.jsons',
    path_segments => ['entries'],
    action => 'jsons',
    view   => '',
    root   => 'http://d.hatena.ne.jp/',
}

=== /entries.hello.json
--- input parse
http://d.hatena.ne.jp/entries.hello.json
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    port   => 80,
    host_port => 'd.hatena.ne.jp:80',
    path   => '/entries.hello.json',
    path_segments => ['entries'],
    action => 'hello',
    view   => 'json',
    root   => 'http://d.hatena.ne.jp/',
}

=== /star.add.json
--- input parse
http://s.hatena.com/star.add.json?uri=httpfoobar
--- expected eval
{
    scheme => 'http',
    host   => 's.hatena.com',
    port   => 80,
    host_port => 's.hatena.com:80',
    path   => '/star.add.json',
    path_segments => ['star'],
    action => 'add',
    view   => 'json',
    root   => 'http://s.hatena.com/',
}

=== /entries/
--- input parse
http://d.hatena.ne.jp/entries/
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    port   => 80,
    host_port => 'd.hatena.ne.jp:80',
    path   => '/entries/',
    path_segments => ['entries', ''],
    action => '',
    view   => '',
    root   => 'http://d.hatena.ne.jp/',
}

=== /entries/.rss
--- SKIP
--- input parse
http://d.hatena.ne.jp/entries/.rss
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    port   => 80,
    host_port => 'd.hatena.ne.jp:80',
    path   => '/entries/.rss',
    path_segments => ['entries', ''],
    action => '',
    view   => 'rss',
    root   => 'http://d.hatena.ne.jp/',
}

=== /entry/list
--- input parse
http://d.hatena.ne.jp/entry/list
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    port   => 80,
    host_port => 'd.hatena.ne.jp:80',
    path   => '/entry/list',
    path_segments => ['entry', 'list'],
    action => '',
    view   => '',
    root   => 'http://d.hatena.ne.jp/',
}

=== /entry.create
--- input parse
http://d.hatena.ne.jp/entry.create
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    port   => 80,
    host_port => 'd.hatena.ne.jp:80',
    path   => '/entry.create',
    path_segments => ['entry'],
    action => 'create',
    view   => '',
    root   => 'http://d.hatena.ne.jp/',
}

=== /entry.create.json
--- input parse
http://d.hatena.ne.jp/entry.create.json
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    port   => 80,
    host_port => 'd.hatena.ne.jp:80',
    path   => '/entry.create.json',
    path_segments => ['entry'],
    action => 'create',
    view   => 'json',
    root   => 'http://d.hatena.ne.jp/',
}
=== path includes ?
--- input parse
http://d.hatena.ne.jp/fanpage/fan/book/%E6%95%B0%E8%A6%9A%E3%81%A8%E3%81%AF%E4%BD%95%E3%81%8B%3F%E2%80%95%E5%BF%83%E3%81%8C%E6%95%B0%E3%82%92%E5%89%B5%E3%82%8A%E3%80%81%E6%93%8D%E3%82%8B%E4%BB%95%E7%B5%84%E3%81%BF?item_key=4152091428
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    port   => 80,
    host_port => 'd.hatena.ne.jp:80',
    path   => '/fanpage/fan/book/%E6%95%B0%E8%A6%9A%E3%81%A8%E3%81%AF%E4%BD%95%E3%81%8B%3F%E2%80%95%E5%BF%83%E3%81%8C%E6%95%B0%E3%82%92%E5%89%B5%E3%82%8A%E3%80%81%E6%93%8D%E3%82%8B%E4%BB%95%E7%B5%84%E3%81%BF',
    path_segments => ['fanpage', 'fan', 'book', '数覚とは何か?―心が数を創り、操る仕組み'],
    action => '',
    view   => '',
    root   => 'http://d.hatena.ne.jp/',
}
