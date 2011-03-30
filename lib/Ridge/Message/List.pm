package Ridge::Message::List;
use strict;
use warnings;
use overload '""' => \&as_html;
use HTML::Entities qw/encode_entities/;
use Ridge::Message;

sub new {
    my ($class, $array) = @_;
    $array ||= [];
    bless $array, $class;
}

sub add {
    my ($self, @messages) = @_;
    push @$self, Ridge::Message->new({ message => $_ }) for @messages;
}

sub as_html {
    my ($self, $class) = @_;
    $class ||= $self->html_class;
    my $out = '';
    if (@$self) {
        $out .= sprintf "%s\n", $_->as_html for @$self;
        $out = sprintf "<ul class=\"$class\">\n%s</ul>\n", $out;
    }
    $out;
}

sub html_class {
    'message';
}

sub as_list {
    $_[0];
}

1;
