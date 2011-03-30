#!/usr/bin/env perl
use strict;
use Test::More qw/no_plan/;
use FindBin;
use Path::Class qw/file/;
use Data::Dumper;
use FindBin;
use FindBin::libs;
use Ridge::Config::App;

## new instance
my $default = Ridge::Config::App->new;

ok $default;
$default->param(foo => 1);
$default->param(bar => 2);
is $default->param('foo'), 1;
is $default->param('bar'), 2;

my $child = Ridge::Config::App->new;
$child->default($default);
is $child->param('foo'), 1;
is $child->param('bar'), 2;
$child->param(child => 'child');
$child->param(childhoge => 'childhoge');
$child->param(foo => 3);
is $child->param('foo'), 3;
is $default->param('foo'), 1;

my $child2 = Ridge::Config::App->new;
$child2->__parent_accessor__($child);
is $child2->param('foo'), 3;
is $child2->param('child'), 'child';
is $child2->param('bar'), 2;
$child2->param(childhoge => 'child2hoge');

my $child3 = Ridge::Config::App->new;
$child3->__parent_accessor__($child2);
is $child3->param('foo'), 3;
is $child3->param('child'), 'child';
is $child2->param('childhoge'), 'child2hoge';
is $child3->param('bar'), 2;


