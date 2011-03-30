package Ridge::ActionResult::Forward;
use strict;
use warnings;
use base qw/Ridge::ActionResult/;
use CLASS;
use Ridge::Flow;

CLASS->mk_accessors(qw/action args/);

sub next_action {
    my ($self, $r, $engine) = @_;
    my $ret = $r->dispatch_to_action($engine, $self->action, $self->args);
    $r->flow(Ridge::Flow->new_from({ engine => ref $engine, action => $self->action }));
    $ret;
}

1;
