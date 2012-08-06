
use strict;
use warnings;
use Ridge::URI::Lite;
use Test::More;
use Ridge::View;
use Path::Class;
use File::Temp qw(tempdir);

my $root = dir(tempdir());

sub mkfile ($) {
    my $name = shift;
    my $file = $root->file('templates', $name);
    $file->parent->mkpath;
    open my $fh, ">", $file;
    print $fh $name;
    close $fh;
}

mkfile('index.html');
mkfile('touch/index.html');
mkfile('touch/index.foo.html');

mkfile('foo.html');

sub U ($$) {
    my $u = Ridge::URI::Lite->new(shift);
    $u->param(device => shift);
    $u;
}

is U('/index.html', 'touch')->to_flow->device, 'touch';

is find_template({
    flow => U('/index.html', 'touch')->to_flow,
    root => $root,
}), "touch/index.html";

is find_template({
    flow => U('/index', 'touch')->to_flow,
    root => $root,
}), "touch/index.html";

is find_template({
    flow => U('/foo.html', 'touch')->to_flow,
    root => $root,
}), "foo.html";

is find_template({
    flow => U('/foo', 'touch')->to_flow,
    root => $root,
}), "foo.html";

is find_template({
    flow => U('/index.foo', 'touch')->to_flow,
    root => $root,
}), "touch/index.foo.html";

done_testing;
