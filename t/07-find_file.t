#!perl
use strict;
use warnings;
use Test::Base;

use Ridge::URI;
use Ridge::View qw/find_file/;

sub find_file_test {
    find_file(Ridge::URI->new($_[0])->to_flow)->stringify;
}

run_is { input => 'expected' }

__END__
===
--- input find_file_test: http://d.hatena.ne.jp/
--- expected: index.html

===
--- input find_file_test: http://d.hatena.ne.jp/entry
--- expected: entry.html

===
--- input find_file_test: http://d.hatena.ne.jp/entry/
--- expected: entry/index.html

===
--- input find_file_test: http://d.hatena.ne.jp/entry.create
--- expected: entry.create.html

===
--- input find_file_test: http://d.hatena.ne.jp/entry/create
--- expected: entry/create.html

===
--- input find_file_test: http://d.hatena.ne.jp/entry.json
--- expected: entry.html

===
--- SKIP
--- input find_file_test: http://d.hatena.ne.jp/entry.yaml
--- expected: entry.html

===
--- SKIP
--- input find_file_test: http://d.hatena.ne.jp/entry.rss
--- expected: entry.html
