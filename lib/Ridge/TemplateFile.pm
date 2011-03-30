package Ridge::TemplateFile;
use strict;
use warnings;
use base qw/Ridge::Object/;
# use overload '""' => \&stringify, fallback => 1;
use CLASS;
use Path::Class ();

CLASS->mk_accessors(qw/path_segments action suffix/);

sub _init {
    if (!$_[0]->suffix) {
        $_[0]->suffix('html');
    }
}

sub prefix {
    my $self = shift;
    my @segments = @{$self->path_segments || []};
    $segments[-1] ||= 'index' if @segments;
    Path::Class::file(grep { $_ } @segments)->stringify || 'index';
}

sub default_template {
    my $self = shift;
    Path::Class::file(join '.', $self->prefix, $self->suffix);
}

sub as_file {
    my $self = shift;
    my $file = $self->prefix;
    $file = join '.', $file, $self->action if $self->action;
    Path::Class::file(join '.', $file, $self->suffix);
}

sub stringify {
    shift->as_file->stringify;
}

sub absolute {
    my $self = shift;
    $self->as_file->absolute(@_);
}

1;
