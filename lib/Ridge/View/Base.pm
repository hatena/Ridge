package Ridge::View::Base;
use strict;
use warnings;
use base qw/Ridge::Object/;
use CLASS;

CLASS->mk_classdata(use_template => 0);
CLASS->mk_classdata(type => '');

sub configure {}

1;
