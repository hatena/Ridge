package Ridge::Plugin::TimeZone;
use strict;
use warnings;
use base qw/Ridge::Plugin/;
use Geo::IP::PurePerl;
use IP::Country::Fast;
use DateTime::TimeZone;
use DateTime;
use List::Util 'first';
use POSIX qw/floor ceil/;
use UNIVERSAL;

sub tz : Method {
    my ( $self, $r, $host ) = @_;
    $host ||= _ipaddr() or return $self->default;
    my %args = (
        GeoLiteCityFile => $self->config->{GeoLiteCityFile},
        host => $host || '',
    );
    return $self->{_time_zone}->{$host} ||= _guess( %args ) || $self->default;
}

sub datetime : Method {
    my ($self, $r, $dt) = @_;
    $dt or return;
    $dt->set_time_zone( $r->tz ) if $r->tz;
    return $dt->ymd . ' ' . $dt->hms;
}

sub default {
    my ($self, $r) = @_;
    return $self->config->{default} || 'UTC';
}

sub _guess {
    my %args = @_;
    return _guess_by_geo_ip( %args ) || _guess_from_country_code( %args );
}

sub _guess_by_geo_ip {
    my %args = @_;
    my $gi = Geo::IP::PurePerl->new(
        $args{GeoLiteCityFile},
        GEOIP_STANDARD
    );
    my $cityref = $gi->get_city_record_as_hash($args{host}) or return;
    my $longitude = $cityref->{longitude} or return;
    my ($numerator, $quotient);
    my $denominator = 15;
    if ($longitude > 0) {
        $numerator = $longitude + 7.5;
        $quotient = floor($numerator / $denominator);
    }
    else {
        $numerator = $longitude - 7.5;
        $quotient = ceil($numerator / $denominator);
    }
    my @names = _get_country_code($cityref->{country_code});
    my $tz;
    my $dt = DateTime->now;
    for my $name ( @names ) {
        $tz = DateTime::TimeZone->new( name => $name );
        my $offset = $tz->offset_for_datetime($dt) / 3600;
        $quotient == $offset and last;
    }
    return UNIVERSAL::isa( $tz, 'DateTime::TimeZone' ) ? $tz->name : undef;
}

sub _guess_from_country_code {
    my %args = @_;
    return unless $args{host};
    my $ic = IP::Country::Fast->new;
    my $cc = $ic->inet_atocc($args{host}) || 'us';
    my @names = _get_country_code($cc);
    return first { defined } @names;
}

sub _get_country_code {
    my $cc = shift or return;
    return DateTime::TimeZone->names_in_country($cc);
}

sub _ipaddr {
    if ($ENV{HTTP_X_FORWARDED_FOR}
            && $ENV{HTTP_X_FORWARDED_FOR} =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/) {
        return $1;
    } elsif ($ENV{REMOTE_ADDR}
                 && $ENV{REMOTE_ADDR} =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/) {
        return $1;
    }
}

1;
