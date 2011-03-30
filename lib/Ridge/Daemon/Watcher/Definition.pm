package Ridge::Daemon::Watcher::Definition;
use strict;
use warnings;
use base qw(Ridge::Object);
use Path::Class qw();

__PACKAGE__->mk_accessors(qw(
    directory root
    file_regexp
    onbeforeupdate onupdate
));

sub _init {
    my $self = shift;
    
    for my $data (qw/directory root file_regexp onbeforeupdate onupdate/) {
        my $default = "default_$data";
        my $value = $self->$data;
        $value = $self->$default
            if not defined $value and $self->can($default);
        $self->$data($value);
    }
}

sub abs_dir {
    my $self = shift;
    
    return $self->{abs_dir} ||= Path::Class::dir($self->directory)->absolute($self->root);
}

sub rel_dir {
    my $self = shift;
    
    return $self->{rel_dir} ||= $_->abs_dir->relative($self->root);
}

sub file_match {
    my ($self, $file) = @_;
    
    my $regexp = $self->file_regexp;
    if ($regexp) {
        return $file =~ $regexp;
    }
    
    return 1;
}

sub process_onbeforeupdate {
    my ($self, $file) = @_;
    
    my $onbeforeupdate = $self->onbeforeupdate;
    return unless $onbeforeupdate;
    
    return unless $self->abs_dir->subsumes($file);
    return unless $self->file_match($file);
    
    $onbeforeupdate->($self, $file);
}

sub process_onupdate {
    my ($self, $file) = @_;

    my $onupdate = $self->onupdate;
    return unless $onupdate;
    
    return unless $self->abs_dir->subsumes($file);
    return unless $self->file_match($file);
    
    $onupdate->($self, $file);
    
    Ridge::Daemon::msg(sprintf 'process %d updating %s', $$, $file);
}

1;
