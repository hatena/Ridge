package Ridge::Message;
use strict;
use warnings;
use CLASS;
use base qw/Ridge::Object/;
use overload '""' => sub { $_[0]->message }, fallback => 1;
use HTML::Entities qw/encode_entities/;

CLASS->mk_accessors(qw/message/);

sub as_html {
    my $self = shift;
    sprintf "<li>%s</li>", encode_entities($_)
}

1;
