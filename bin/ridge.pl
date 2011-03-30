#!/usr/bin/env perl
use strict;
use warnings;
use FindBin::libs;
use Path::Class qw/dir/;
use Cwd;
use Getopt::Long;
use Pod::Usage;
use Ridge::Helper;

my $help  = 0;
GetOptions('h|help|?' => \$help);

pod2usage(1) if ($help || !$ARGV[0]);

my $init = Ridge::Helper->new({
    root => dir(Cwd::getcwd, $ARGV[0]),
    argv => [ 'Init', @ARGV ],
});
$init->run;

__END__

=head1 NAME

ridge.pl - Bootstrap a Ridge application

=head1 SYNOPSIS

ridge.pl [options] application-name

 Options:
    -help        display this help and exits

 application-name has to be a valid Perl module name.

 Examples:
    ridge.pl Bookmark
    ridge.pl Diary
    ridge.pl Hatena::Diary

=head1 DESCRIPTION

Bootstrap a Ridge application.

=head1 AUTHOR

Naoya Ito, C<platform@hatena.ne.jp>

=cut
