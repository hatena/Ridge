package Ridge::View::YAML;
use strict;
use warnings;
use base qw/Ridge::View::Base/;

use YAML::Syck;
use HTTP::Status;
use CLASS;

CLASS->type('yaml');

sub process {
    my ($self, $r) = @_;
    $r->res->content_type('text/x-yaml');
    if (not %{$r->stash->exposed_params}) {
        $r->res->code(RC_NOT_FOUND);
        return;
    }
    return YAML::Syck::Dump($r->stash->exposed_params->to_hash);
}

1;
