package Ridge::View::JSON;
use strict;
use warnings;
use base qw/Ridge::View::Base/;

use JSON::Syck;
use Encode qw/from_to/;
use Encode::JavaScript::UCS;
use HTTP::Status;
use CLASS;

CLASS->mk_classdata(callback_name => 'callback');
CLASS->type('json');

sub validate_callback_param ($) {
    return shift =~ /^[a-zA-Z0-9\.\_\[\]]+$/;
}

sub configure {
    my ($self, $config) = @_;
    if (ref $config->param('View::JSON') and
        my $cb_param = $config->param('View::JSON')->{callback_param}) {
        $self->callback_name($cb_param);
    }
}

sub process {
    my ($self, $r) = @_;
    $r->res->content_type('application/json');
    if (not %{$r->stash->exposed_params}) {
        $r->res->code(RC_NOT_FOUND);
        return;
    }
    my $json = JSON::Syck::Dump($r->stash->exposed_params->to_hash);
    from_to($json, 'utf8', 'JavaScript-UCS');

    # IE用糞hack
    $json =~ s!<!\\u003c!g;
    $json =~ s!>!\\u003e!g;

    my $callback = $r->req->param($self->callback_name);
    if ($callback) {
        validate_callback_param $callback
            or Ridge::Exception->throw('Invalid callback parameter');
        $r->res->content_type('text/javascript');
        return sprintf '%s(%s);', $callback, $json;
    } else {
        return $json;
    }
}

1;
