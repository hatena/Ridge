package Ridge::ActionResult;
use strict;
use warnings;
use base qw/Ridge::Object/;
use UNIVERSAL::require;

use Ridge::ActionResult::Default;
use Ridge::ActionResult::Forward;
use Ridge::ActionResult::Message;
use Ridge::ActionResult::Follow;

sub as {
    my ($class, $status, $args) = @_;
    $args ||= {};
    my $module = join('::', __PACKAGE__, ucfirst $status);
    $module->new($args);
}

sub has_next_action {
    my $self = shift;
    $self->is_forward or $self->is_message or $self->is_follow;
}

sub is_forward {
    shift->isa('Ridge::ActionResult::Forward');
}

sub is_message {
    shift->isa('Ridge::ActionResult::Message');
}

sub is_follow {
    shift->isa('Ridge::ActionResult::Follow');
}

1;
