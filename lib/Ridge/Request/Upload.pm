package Ridge::Request::Upload;

use strict;
use warnings;

use overload '""' => \&as_string;
use overload '<>' => \&as_iterate;
use overload '*{}' => \&as_glob;
use IO::File;

use base qw(Plack::Request::Upload);

sub as_string { $_[0]->{filename} }

sub as_iterate {
    my ($self) = @_;
    my $fh = $self->as_glob;
    <$fh>
}

sub as_glob {
    my ($self) = @_;
    $self->{fh} ||= IO::File->new($self->tempname, 'r');
    $self->{fh};
}

sub DESTROY {
    my ($self) = @_;
    close $self->{fh} if $self->{fh};
}

1;
__END__



