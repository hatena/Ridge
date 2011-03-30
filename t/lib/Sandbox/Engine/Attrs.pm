package Sandbox::Engine::Attrs;
use strict;
use warnings;
use Sandbox::Engine -Base;

sub default : Public { $_[1]->res->content('Hello') }
sub public  : Public {}
sub private {}
sub _foobar {}

1;
