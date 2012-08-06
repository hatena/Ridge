package Ridge::Request;
use strict;
use warnings;
use HTML::Entities qw/encode_entities/;
use base qw/ Plack::Request /;

use UNIVERSAL::require;
use FormValidator::Simple;
use Encode;
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;

use Ridge::Util qw/deprecated/;
use Ridge::Request::Upload;
use DateTime;
use URI;
use URI::Escape ();
use Hash::MultiValue;

our $PREFERRED_URI = 'Ridge::URI';
our $PREFERRED_BROWSER = 'Ridge::Browser';

sub validator {
    my $self = shift;
    $self->{_validator} ||= FormValidator::Simple->new;
}

sub form {
    my $self = shift;
    if (@_) {
        my $form = $_[1] ? [ @_ ] : $_[0];
        $self->validator->check($self, $form);
    }
    $self->validator->results;
}

sub getenv {
    my ($self, $key) = @_;
    my $v = $self->{env}->{$key};
    return $v if defined $v;
    return $ENV{$key};
}

sub server_name {
    my $self = shift;
    return $self->{env}->{'SERVER_ADDR'} || $self->{env}->{'SERVER_NAME'} || 'unknown';
}

sub is_idempotent {
    my $self = shift;
    my $method = $self->request_method || '';
    return ($method eq 'GET' or $method eq 'HEAD');
}

sub is_tls {
    my $self = shift;
    return uc($self->getenv('HTTPS') || '') eq 'ON';
}

sub serialize {
    my $self = shift;
    my $option;
    if (ref $_[0] eq 'HASH') {
        $option = shift;
    } elsif (@_ > 1) {
        my %option = @_;
        $option = \%option;
    } elsif (not @_) {
        $option = {};
    } else {
        croak "Invalid parameter for serialize()";
    }

    my @targets;
    if ($option->{only}) {
        @targets = @{$option->{only}};
    } elsif ($option->{exclude}) {
        my $regex = join '|', @{$option->{exclude}};
        @targets = grep { not m/(^$regex$)/ } $self->param
    } else {
        @targets = $self->param;
    }

    my @hidden;
    for my $key (@targets) {
        for my $value ($self->param($key)) {
            push @hidden,
                sprintf(
                    '<input type="hidden" name="%s" value="%s" />',
                    encode_entities($key, '<>&"'),
                    encode_entities($value, '<>&"'),
                );
        }
    }
    join "\n", @hidden;
}

sub raw_data {
    my $self = shift;
    $self->content;
}

sub browser {
    my ($self) = @_;
    $self->{_browser} ||= do {
        $Ridge::Request::PREFERRED_BROWSER->require or die $@;
        $Ridge::Request::PREFERRED_BROWSER->new( $self->user_agent || '');
    };
}

sub charset {
    my ($self, $val) = @_;
    if (defined $val) {
        $self->{charset} = $val;
    }
    $self->{charset};
}

sub uri {
    my $self = shift;
    $self->{uri} ||= do {
        # Use $self->_uri_base to leave default port (:80 on http: or
        # :443 on https:) as it is. This is a backward compatible way.
        my $uri = URI->new($self->_uri_base);
        $uri->path_query($self->env->{REQUEST_URI});

        $Ridge::Request::PREFERRED_URI->use or die $@;
        $Ridge::Request::PREFERRED_URI->new($uri);
    };
}

sub escaped_uri { # always return new uri object
    my $self = shift;
    $self->SUPER::uri;
}

sub original_uri {
    my ($self) = @_;
    my $uri = $self->base;
    $uri->path_query($self->env->{REQUEST_URI});
    return $uri;
}

sub Vars { # _deprecated
    my ($self) = @_;
    deprecated 'parameters';
    $self->parameters;
}

sub request_method {
    my ($self) = @_;
    $self->method || 'GET';
}

sub get_header { # _deprecated
    my ($self, $key) = @_;
    deprecated '$self->headers->header($key) or $self->headers->header_field_names;';
    $key ? $self->headers->header($key) : $self->headers->header_field_names;
}

sub server_port {
    my ($self) = @_;
    $self->port;
}

sub virtual_host {
    my ($self) = @_;
    my $vh = $self->env->{'X_FORWARDED_HOST'} || $self->env->{'HOST'} || $self->server_name;
    $vh =~ s/:\d+$//;
    $vh;
}


sub _decode_utf8 ($) {
    my $data = shift;
    return $data if ref $data and ref $data eq 'Fh';
    decode_utf8 $data;
}

sub parameters {
    my $self = shift;

    $self->env->{'plack.request.merged'} ||= do {
        my $query  = $self->query_parameters;
        my $body   = $self->body_parameters;
        my $upload = [ map { $_ => $self->upload($_)->filename } $self->upload ];
        Hash::MultiValue->new(
            $query->flatten,
            $body->flatten,
            @$upload
        );
    };
}

sub param {
    my $self = shift;

    return $self->SUPER::param unless @_;

    # $req->param(-name => 'simple', -value => 'baz')
    if (@_ == 4) {
        my %args   = @_;
        my $params = $self->parameters;
        my $name   = $args{-name};
        my $value  = $args{-value};

        $params->remove($name);
        $params->add($name, (ref($value) eq 'ARRAY') ? @$value : $value);

        return $self;
    }

    # $req->param(
    #     aaa => 'vaa',
    #     bbb => 'vbb',
    #     ccc => [qw/vc1 vc2/],
    # );
    if (@_ % 2 == 0) {
        my %args = @_;
        my $params = $self->parameters;
        for my $name (keys %args) {
            my $value = $args{$name};
            $name =~ s/^-//;
            
            $params->remove($name);
            $params->add($name, (ref($value) eq 'ARRAY') ? @$value : $value);
        }
        return $self;
    }

    # retrieve

    if ($_[0] eq 'POSTDATA') {
        return $self->content;
    }

    my $charset = $self->charset || '';
    if ($charset eq 'utf-8' or $charset eq 'utf8') {
        wantarray ? map { _decode_utf8 $_ } $self->SUPER::param(@_)
                  : _decode_utf8 $self->SUPER::param(@_);
    } else {
        $self->SUPER::param(@_);
    }
}

sub cookies {
    my ($self) = @_;

    if (!$self->env->{'plack.cookie.parsed'} && $self->env->{HTTP_COOKIE}) {
        # Treat '+' as a space to accept cookies encoded by Apache2::Cookie.
        $self->env->{HTTP_COOKIE} =~ s/\+/%20/g;
    }

    return $self->SUPER::cookies;
}

sub cookie {
    my ($self, $name) = @_;
    croak 'require name' unless $name;

    $self->cookies->{$name};
}

sub _make_upload {
    my ($self, $upload) = @_;
    Ridge::Request::Upload->new(
        headers => HTTP::Headers->new( %{delete $upload->{headers}} ),
        %$upload,
    );
}

sub set_param {
    my ($self, $name, $value) = @_;
    my $params = $self->parameters;
    $params->remove($name);
    $params->add($name, (ref($value) eq 'ARRAY') ? @$value : $value);
    return $self;
}

sub epoch_param {
    my $self = shift;

    if (wantarray) {
        return map { defined && /^[0-9]+$/ ? DateTime->from_epoch(epoch => $_) : () } ($self->param($_[0]));
    } else {
        my $v = $self->param($_[0]);
        return undef unless defined $v;
        return undef unless $v =~ /^[0-9]+$/;
        return DateTime->from_epoch(epoch => $v);
    }
}

sub address {
    my $self = shift;
    if (my $for = $self->getenv('HTTP_X_FORWARDED_FOR')) {
        my @ip = grep { $_ and not /^(?:10\.|172\.(?:1[6-9]|2[0-9]|3[0-1])\.|192\.168\.|127\.)/ and $_ ne '::1' } split /\s*,\s*/, $for;
        return $ip[-1] if @ip;
    }
    return $self->getenv('REMOTE_ADDR');
}

1;
