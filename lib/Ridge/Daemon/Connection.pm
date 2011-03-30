package Ridge::Daemon::Connection;
use strict;
use warnings;
use base qw/Ridge::Object/;
use CLASS;

CLASS->mk_accessors(qw/socket wheel keepalive outbuf response/);

*res = \&response;

sub id {
    shift->wheel->ID;
}

sub flush {
    my $self = shift;
    $self->wheel->put($self->res);
    $self->res(undef);
}

sub flush_outbuf {
    my $self = shift;
    $self->wheel->set_output_filter(POE::Filter::Stream->new);
    $self->wheel->put($self->outbuf);
    $self->outbuf(undef);
    $self->res(undef);
}

sub flush_header {
    my $self = shift;
    my $content = $self->res->content;
    $self->res->content('');
    $self->wheel->put($self->res);
    $self->outbuf($content) if $content;
}

1;
