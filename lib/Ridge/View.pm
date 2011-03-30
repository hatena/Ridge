package Ridge::View;
use strict;
use warnings;
use base qw/Ridge::Object/;

use CLASS;
use Carp;
use Exporter::Lite;
use List::MoreUtils qw/any/;
use Path::Class qw/dir/;
use UNIVERSAL::require;

use Ridge::TemplateFile;

## for preloading
use Ridge::View::TT;
use Ridge::View::JSON;
use Ridge::Exceptions;

our @EXPORT = qw/find_file find_template/;
CLASS->mk_accessors(qw/filename/);

my %Impl;
sub impl {
    my ($self, $impl, $config) = @_;
    return $Impl{$impl} if $Impl{$impl};

    eval {
        my $module = join '::', CLASS, $impl;
        $module->require or die $@;
        my $inst = $module->new;
        $inst->configure($config);
        $Impl{$impl} = $inst;
    };
    if ($@) {
        Ridge::Exception::TemplateNotFound->throw(error => $@);
    }

    $Impl{$impl} or Ridge::Exception::TemplateNotFound->throw(error => 'Failed to instantiate impl:' . $impl);
    return $Impl{$impl};
}

sub find_file ($) {
    my $flow = shift or croak "need Ridge::Flow as argument";
    Ridge::TemplateFile->new({
        path_segments => $flow->path_segments,
        action        => $flow->action || '',
    });
}

sub available {
    my $self = shift;
    @_ ? $self->{_available} = [ @_ ] : @{$self->{_available} || [qw/html/] };
}

sub is_available {
    my ($self, $type) = @_;
    any { $_ eq $type } $self->available;
}

my %Cache;
sub find_template ($) {
    my $args = shift;
    croak "argument 'flow' and 'root' must be required"
        if not defined $args->{flow} or not defined $args->{root};

    my $flow = $args->{flow};

    if (my $cached =  $Cache{$flow->as_key}) {
        return $cached;
    }

    my $file = find_file $flow;
    my $found = $file->absolute(dir($args->{root}, 'templates'))->stat
        ? $file : $file->default_template;

    $Cache{$flow->as_key} = $found;
    $found;
}

1;
