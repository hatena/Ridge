package Ridge::Exceptions;
use strict;
use warnings;
use Exporter::Lite;
use Scalar::Util qw/blessed/;

use Exception::Class (
    'Ridge::Exception::TemplateError' => {
        isa => 'Ridge::Exception',
    },
    'Ridge::Exception::TemplateNotFound' => {
        isa => 'Ridge::Exception::TemplateError',
    },
    'Ridge::Exception::NoSuchAction' => {
        isa    => 'Ridge::Exception',
        fields => [qw/action engine/],
    },
    'Ridge::Exception::RequestError' => {
        isa    => 'Ridge::Exception',
        fields => [qw/filename code after_filter/],
    }
);

our @EXPORT = qw/throw caught rethrow/;

sub rethrow ($) {
    my $e = shift;
    local $SIG{__DIE__};
    blessed $e && $e->isa('Ridge::Exception') ? $e->rethrow : die $e;
}

sub throw {
    Ridge::Exception->throw(@_);
}

sub caught {
    Exception::Class->caught($_[0]);
}

sub Ridge::Exception::RequestError::do_task {
    my ($self, $r) = @_;
    $r->res->code($self->code);

    my $html = $r->path_to(
        'templates',
        '_error',
        $self->filename || sprintf('%s.html', $self->code)
    )->stringify;

    if (-r $html) {
        my $view = $r->view->impl('TT', $r->config);
        $r->res->content_type('text/html');
        my $content = $view->process($r, $html);
        $content = Encode::is_utf8($content) ? Encode::encode_utf8($content) : $content;
        $r->res->content($content);
    } else {
        $r->res->content_type('text/plain') unless $r->res->content_type;
        $r->res->content($r->res->status_line);
    }
    my $filter = $self->after_filter;
    $filter->($self, $r) if $filter;
}

1;
