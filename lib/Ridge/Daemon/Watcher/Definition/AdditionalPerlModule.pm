package Ridge::Daemon::Watcher::Definition::AdditionalPerlModule;
use strict;
use warnings;
use Ridge::Daemon::Watcher::Definition;
push our @ISA, qw(Ridge::Daemon::Watcher::Definition);
use Path::Class qw(file);

__PACKAGE__->mk_classdata(default_directory => 'yet/another/lib');
__PACKAGE__->mk_classdata(default_file_regexp => qr{\.pm$});

1;
