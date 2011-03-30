package Ridge::Cookie;

use strict;
use warnings;
use CGI::Util;
use URI::Escape;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(name domain path expires secure httponly value));


sub new {
    my ($class, %val) = @_;
    bless {
        name     => $val{-name},
        domain   => $val{-domain},
        path     => $val{-path},
        expires  => $val{-expires},
        secure   => $val{-secure},
        httponly => $val{-httponly},
        value    => $val{-value},
    }, $class;
}

sub bake {
    my ($self) = @_;
    my @cookie = ( URI::Escape::uri_escape_utf8($self->name) . "=" . URI::Escape::uri_escape_utf8($self->value) );
    push @cookie, "domain=" . $self->{domain} if $self->{domain};
    push @cookie, "path=" . $self->{path}     if $self->{path};
    push @cookie, "expires=" . CGI::Util::expires($self->{expires}) if $self->{expires};
    push @cookie, "secure"                    if $self->{secure};
    push @cookie, "HttpOnly"                  if $self->{httponly};

    return join "; ", @cookie;
}

1;
__END__



