package Ridge::Helper::ConfigLoggerYAML;
use strict;
use warnings;

use base qw/Ridge::Helper/;
use Cwd;

sub create {
    my $self = shift;
    $self->render_file('config/logger/default.yml');
}

1;

__DATA__
---
dispatchers:
  - file
  - screen

file:
  class: Log::Dispatch::File
  min_level: debug
  filename: /dev/null
  mode: append
  format: '[%d] [%p] %m at %F line %L%n'

screen:
  class: Log::Dispatch::Screen
  min_level: debug
  stderr: 1
  format: '%m%n'
