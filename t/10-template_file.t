#!perl
use strict;
use warnings;
use Test::Base;

use Ridge::TemplateFile;

sub stringify {
    Ridge::TemplateFile->new($_[0])->stringify;
}

sub absolute_path {
    Ridge::TemplateFile->new($_[0])->absolute('/home/root');
}

sub default_template {
    Ridge::TemplateFile->new($_[0])->default_template;
}

__END__
===
--- input eval stringify
{ path_segments => [] }
--- expect: index.html

===
--- input eval stringify
{ path_segments => [qw/index/] }
--- expect: index.html

===
--- input eval stringify
{ path_segments => [qw/path to index/] }
--- expect: path/to/index.html

===
--- input eval stringify
{ path_segments => ['path','to',''] }
--- expect: path/to/index.html

===
--- input eval stringify
{ path_segments => [qw/path to index/], action => 'hello' }
--- expect: path/to/index.hello.html

===
--- input eval absolute_path
{ path_segments => [qw/index/] }
--- expect: /home/root/index.html

===
--- input eval absolute_path
{ path_segments => [qw/path to index/] }
--- expect: /home/root/path/to/index.html

===
--- input eval absolute_path
{ path_segments => ['path','to',''] }
--- expect: /home/root/path/to/index.html

===
--- input eval absolute_path
{ path_segments => [qw/path to index/], action => 'hello' }
--- expect: /home/root/path/to/index.hello.html

===
--- input eval default_template
{ path_segments => [qw/index/] }
--- expect: index.html

===
--- input eval default_template
{ path_segments => [qw/index/], action => 'hello' }
--- expect: index.html
