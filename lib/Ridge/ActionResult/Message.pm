package Ridge::ActionResult::Message;
use strict;
use warnings;
use base qw/Ridge::ActionResult/;
use overload '""' => \&as_string, fallback => 1;
use CLASS;
use Path::Class qw/file/;

CLASS->mk_accessors(qw/name message args/);

sub next_action {
    my ($self, $r, $engine) = @_;
    -r $r->path_to('templates', '_message',  $self->name . '.html')
        ? do { $r->view->filename(file('_message', $self->name . '.html')->stringify);
               $r->stash->param(message => $self) }
        : $r->res->content_as_text($self->as_string);
}

*stringify = \&as_string;

sub as_string {
    shift->message;
}

1;
