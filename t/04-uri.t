#!perl
use strict;
use warnings;
use Test::Base;
use URI::Escape;

URITest->runtests(+ 1 * blocks);

sub parse {
    my $uri = Ridge::URI->new($_[0]);
    return {
        (map { $_ => $uri->$_ || '' } qw/host scheme path path_segments action view root/),
    }
}

sub parse_extend {
    Ridge::URI->replace_syntax(q(
        # Serivece specific definitions.
        # This is an example for "Hatena Diary" pages.
        path : reserved_path | keyword_path | user_path | default_path
        reserved_path : '/' /(config|profile)/ default_path {
            $return = {
                path_segments => [$item[2], @{$item[3]->{path_segments}}],
                action => $item[3]->{action},
                view => $item[3]->{view},
            }
        }
        keyword_path : '/keyword/' keyword {
            $return = {
                path_segments => ['keyword'],
                action => '',
                view => '',
                params => { keyword => URI::Escape::uri_unescape($item[2]) },
            };
        }
        keyword : /[^\/]+/
        user_path : '/' user_name default_path {
            $return = $item[3];
            $return->{params}->{name} = $item[2];
        }
        user_name : /[A-Za-z][\w\-]{1,13}[A-Za-z0-9]/
    ));
    my $uri = Ridge::URI->new($_[0]);
    Ridge::URI->replace_syntax(q(
        path : default_path
    ));
    my $return = {
        (map { $_ => $uri->$_ || '' } qw/host scheme path path_segments action view root/),
        name => $uri->param('name') || '',
    };
    $return->{keyword} = $uri->param('keyword') if $uri->param('keyword');
    return $return;
}

sub parse_extend_view {
    Ridge::URI->replace_syntax(q(
        view : /\.(html|rss2|rss|json|atom)/ { $1 }
    ));
    my $uri = Ridge::URI->new($_[0]);
    Ridge::URI->replace_syntax(q(
        view : /\.(html|rss|json)/ { $1 }
    ));
    return {
        (map { $_ => $uri->$_ || '' } qw/host scheme path path_segments action view root/),
        name => $uri->param('name') || '',
    }
}

sub parse_group_name {
    Ridge::URI->replace_syntax(q(
        uri          : scheme '://' host path {
            $return = $item[4];
            if ($item[3]) {
                $return->{params}->{group_name} = $item[3];
                unshift @{$return->{path_segments}}, 'group';
            }
        }
        host         : group_name(?) 'g.hatena.ne.jp' { $item[1]->[0] }
        group_name   : /([\w-]+)\./ { $1 }
    ));
    my $uri = Ridge::URI->new($_[0]);
    Ridge::URI->replace_syntax(q(
        uri          : scheme '://' host path
        host         : /[\w-.]+/
    ));
    return {
        path_segments => $uri->path_segments,
        group_name => $uri->param('group_name'),
    };
}

run_is_deeply;

package URITest;
use base qw/Test::Class/;
use Test::More;
use Ridge::URI;

sub test_instance : Test(3) {
    my $uri = Ridge::URI->new('http://d.hatena.ne.jp/naoya/');
    isa_ok $uri, 'URI';
    isa_ok $uri, 'Ridge::URI';
    is $uri->host, 'd.hatena.ne.jp';
}

sub test_multiple_forwarded_host : Test(3) {
    my $uri = Ridge::URI->new('http://d.hatena.ne.jp%2C%20b.hatena.ne.jp/naoya/');
    isa_ok $uri, 'URI';
    isa_ok $uri, 'Ridge::URI';
    is $uri->host, 'd.hatena.ne.jp';
}

sub test_as_uri : Test(5) {
    my $uri = Ridge::URI->new('http://test/foo/bar?baz#abc');
    is_deeply $uri->path_segments, [qw/foo bar/];
    
    my $clone = $uri->as_uri;
    isa_ok $clone, 'URI';
    ok !$clone->isa('Ridge::Lite');
    is $clone . '', q<http://test/foo/bar?baz#abc>;
    
    undef $clone;
    
    # If you used |clone| in place of |as_uri|, this would be
    # broken...
    is_deeply $uri->path_segments, [qw/foo bar/];
}

__END__
=== /
--- input parse
http://d.hatena.ne.jp/
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
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
    path   => '/entry.create.json',
    path_segments => ['entry'],
    action => 'create',
    view   => 'json',
    root   => 'http://d.hatena.ne.jp/',
}
=== /naoya/
--- input parse_extend
http://d.hatena.ne.jp/naoya/
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/naoya/',
    path_segments => [''],
    action => '',
    view   => '',
    name   => 'naoya',
    root   => 'http://d.hatena.ne.jp/',
}
=== /naoya
--- input parse_extend
http://d.hatena.ne.jp/naoya
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/naoya',
    path_segments => ['naoya'],
    action => '',
    view   => '',
    name   => '',
    root   => 'http://d.hatena.ne.jp/',
}
=== /naoya/entry
--- input parse_extend
http://d.hatena.ne.jp/naoya/entry
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/naoya/entry',
    path_segments => ['entry'],
    action => '',
    view   => '',
    name   => 'naoya',
    root   => 'http://d.hatena.ne.jp/',
}
=== /naoya/entry.create
--- input parse_extend
http://d.hatena.ne.jp/naoya/entry.create
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/naoya/entry.create',
    path_segments => ['entry'],
    action => 'create',
    view   => '',
    name   => 'naoya',
    root   => 'http://d.hatena.ne.jp/',
}
=== /naoya/entry/list
--- input parse_extend
http://d.hatena.ne.jp/naoya/entry/list
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/naoya/entry/list',
    path_segments => ['entry', 'list'],
    action => '',
    view   => '',
    name   => 'naoya',
    root   => 'http://d.hatena.ne.jp/',
}
=== /naoya/entry/list.rss
--- SKIP
--- input parse_extend
http://d.hatena.ne.jp/naoya/entry/list.rss
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/naoya/entry/list.rss',
    path_segments => ['entry', 'list'],
    action => '',
    view   => 'rss',
    name   => 'naoya',
    root   => 'http://d.hatena.ne.jp/',
}
=== /naoya/entry/list.create
--- input parse_extend
http://d.hatena.ne.jp/naoya/entry/list.create
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/naoya/entry/list.create',
    path_segments => ['entry', 'list'],
    action => 'create',
    view   => '',
    name   => 'naoya',
    root   => 'http://d.hatena.ne.jp/',
}
=== /config/design
--- input parse_extend
http://d.hatena.ne.jp/config/design
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/config/design',
    path_segments => ['config', 'design'],
    action => '',
    view   => '',
    name   => '',
    root   => 'http://d.hatena.ne.jp/',
}
=== /profile/icon.upload
--- input parse_extend
http://d.hatena.ne.jp/profile/icon.upload
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/profile/icon.upload',
    path_segments => ['profile', 'icon'],
    action => 'upload',
    view   => '',
    name   => '',
    root   => 'http://d.hatena.ne.jp/',
}
=== /config/design/form
--- input parse_extend
http://d.hatena.ne.jp/config/design/form
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/config/design/form',
    path_segments => ['config', 'design', 'form'],
    action => '',
    view   => '',
    name   => '',
    root   => 'http://d.hatena.ne.jp/',
}
=== /config/design/form.update
--- input parse_extend
http://d.hatena.ne.jp/config/design/form.update
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/config/design/form.update',
    path_segments => ['config', 'design', 'form'],
    action => 'update',
    view   => '',
    name   => '',
    root   => 'http://d.hatena.ne.jp/',
}
=== /naoya/config/design/form.update.json
--- input parse_extend
http://d.hatena.ne.jp/naoya/config/design/form.update.json
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/naoya/config/design/form.update.json',
    path_segments => ['config', 'design', 'form'],
    action => 'update',
    view   => 'json',
    name   => 'naoya',
    root   => 'http://d.hatena.ne.jp/',
}
=== /keyword/Perl
--- input parse_extend
http://d.hatena.ne.jp/keyword/Perl
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/keyword/Perl',
    path_segments => ['keyword'],
    action => '',
    view   => '',
    name   => '',
    keyword => 'Perl',
    root   => 'http://d.hatena.ne.jp/',
}
=== /keyword/Programming%20Perl
--- input parse_extend
http://d.hatena.ne.jp/keyword/Programming%20Perl
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/keyword/Programming%20Perl',
    path_segments => ['keyword'],
    action => '',
    view   => '',
    name   => '',
    keyword => 'Programming Perl',
    root   => 'http://d.hatena.ne.jp/',
}
=== /keyword/Computer%20Science%20%26%20Perl%20Programming
--- input parse_extend
http://d.hatena.ne.jp/keyword/Computer%20Science%20%26%20Perl%20Programming
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/keyword/Computer%20Science%20%26%20Perl%20Programming',
    path_segments => ['keyword'],
    action => '',
    view   => '',
    name   => '',
    keyword => 'Computer Science & Perl Programming',
    root   => 'http://d.hatena.ne.jp/',
}
=== /keyword.edit?keyword=Perl
--- input parse_extend
http://d.hatena.ne.jp/keyword.edit?keyword=Perl
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/keyword.edit',
    path_segments => ['keyword'],
    action => 'edit',
    view   => '',
    name   => '',
    root   => 'http://d.hatena.ne.jp/',
}
=== /blogs.atom
--- input parse_extend_view
http://d.hatena.ne.jp/blogs.atom
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/blogs.atom',
    path_segments => ['blogs'],
    action => '',
    view   => 'atom',
    name   => '',
    root   => 'http://d.hatena.ne.jp/',
}
=== /blogs.rss2
--- input parse_extend_view
http://d.hatena.ne.jp/blogs.rss2
--- expected eval
{
    scheme => 'http',
    host   => 'd.hatena.ne.jp',
    path   => '/blogs.rss2',
    path_segments => ['blogs'],
    action => '',
    view   => 'rss2',
    name   => '',
    root   => 'http://d.hatena.ne.jp/',
}
=== hatena.g.hatena.ne.jp
--- input parse_group_name
http://hatena.g.hatena.ne.jp/
--- expected eval
{
    group_name => 'hatena',
    path_segments => ['group',''],
}
=== help.g.hatena.ne.jp
--- input parse_group_name
https://help.g.hatena.ne.jp/hatenatips/
--- expected eval
{
    group_name => 'help',
    path_segments => ['group','hatenatips',''],
}
