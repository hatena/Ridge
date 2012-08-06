package Ridge::Response;
use strict;
use warnings;
use base qw/Plack::Response/;

use Carp qw/croak/;
use HTTP::Status ();
use URI;
use Ridge::Cookie;

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self->_init(@args);
    bless $self, $class;
}

sub _init {
    my $self = shift;
    $self->{_cookies} = [];
}

sub cookie {
    my ($self, %val) = @_;
    $self->add_cookie(Ridge::Cookie->new(%val));
}

sub add_cookie {
    my ($self, @cookies) = @_;
    push @{$self->{_cookies}}, @cookies;
}

sub cookies {
    my $self = shift;
    wantarray ? @{$self->{_cookies}} : $self->{_cookies};
}

sub _finalize_cookies {
    my ($self, $headers) = @_;
    for my $cookie (@{ $self->{_cookies} }) {
        # Plack 0.9983 移行で引数の $headers に push_header するようになったのに追従
        my $baked = $cookie->bake;
        $headers->push_header( 'Set-Cookie' => $baked ) if $headers;
        $self->headers->push_header( 'Set-Cookie' => $baked );
    }
}

sub content_as_text {
    my ($self, $text) = @_;
    $self->content_type('text/plain');
    $self->content($text);
    $self->content;
}

sub content {
    my $self = $_[0];
    if (@_ > 1) {
        utf8::encode($_[1]) if utf8::is_utf8($_[1]);
        $self->SUPER::content($_[1]);
    } else {
        $self->SUPER::content;
    }
}


sub charset {
    my $self = shift;
    @_ ? $self->{_charset} = shift : $self->{_charset};
}

sub redirect {
    my ($self, $to, $code) = @_;
    $to or croak "Invalid argument. (missing URL)";
    $to =~ s/[\x00-\x1F\x7F]+//g;
    if ($to !~ /^(\/|https?:)/) {
        croak "redirect uri must be http(s)";
    }

    # Escape characters that are invalid as URI.
    my $to_uri = URI->new($to);
    $self->SUPER::redirect($to_uri->as_string, $code || 302);
    return; # for using with some functions.
}

sub redirect_permanently {
    my ($self, $to) = @_;
    $self->redirect($to, 301);
}

sub request {
    my ($self, $val) = @_;
    if (defined $val) {
        $self->{request} = $val;
    }
    $self->{request};
}

sub push_header {
    my ($self, @args) = @_;
    $self->headers->push_header(@args);
}

sub status_line {
    my ($self) = @_;
    sprintf('%s %s',
        $self->status || '000',
        $self->message || HTTP::Status::status_message($self->status),
    );
}

sub message {
    my ($self, $val) = @_;
    if (defined $val) {
        $self->{message} = $val;
    }
    $self->{message};
}

sub is_info     { HTTP::Status::is_info     (shift->status); }
sub is_success  { HTTP::Status::is_success  (shift->status); }
sub is_redirect { HTTP::Status::is_redirect (shift->status); }
sub is_error    { HTTP::Status::is_error    (shift->status); }

sub content_type {
    my $self = shift;
    if (@_) {
        my $type = shift;
        $self->SUPER::content_type($type);
    } else {
        $self->SUPER::content_type;
    }
    $self->header('Content-Type') || '';
}


1;
