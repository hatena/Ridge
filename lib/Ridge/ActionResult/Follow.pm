package Ridge::ActionResult::Follow;
use strict;
use warnings;
use base qw/Ridge::ActionResult/;
use CLASS;

use Ridge::Exceptions qw/caught rethrow/;
use HTTP::Status;

CLASS->mk_accessors(qw/action args/);

sub next_action {
    my ($self, $r, $engine) = @_;
    my $e;
    my $retval = eval {
        $r->dispatch_to_action($engine, $self->action, $self->args);
    };
    if ($e = caught('Ridge::Exception::NoSuchAction')) {
        Ridge::Exception::RequestError->throw(code => RC_METHOD_NOT_ALLOWED);
    } elsif ($e = caught()) {
        rethrow $e;
    }
    $retval;
}

1;
