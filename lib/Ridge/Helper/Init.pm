package Ridge::Helper::Init;
use strict;
use warnings;
use base qw/Ridge::Helper/;

sub create {
    my $self = shift;
    for my $helper (qw/Ridge Root Server Create Index Config ConfigLoggerYAML PSGI/) {
        Ridge::Helper->new({
            namespace => $self->argv->[0],
            root      => $self->root,
            argv      => [ $helper ]
        })->run;
    }
    $self->mk_dir($_)
        for qw(static/images static/css static/js script templates config config/logger);
}

1;
