package Ridge::Browser;

use strict;
use warnings;
use base qw(Class::Accessor::Lvalue::Fast);
use Params::Validate qw(validate_pos);
use HTTP::MobileAgent;
use HTTP::BrowserDetect;

__PACKAGE__->mk_accessors(qw/browser/);

# See also: modules/Updu/config/proxy/clientinfo.conf

sub new {
    my $class = shift;
    my $self = $class->SUPER::new;
    $self->_init(@_);
    return $self;
}

sub _init {
    my ($self, $ua) = validate_pos(@_, 1, 1);
    my $agent = HTTP::MobileAgent->new($ua);
    $self->browser
        = $agent->is_non_mobile ? HTTP::BrowserDetect->new($ua) : $agent;
}

sub is_mobile {
    my $klass = ref shift->browser;
    return ( $klass ne 'HTTP::MobileAgent::NonMobile' && $klass ne 'HTTP::BrowserDetect' );
}

sub is_non_mobile {
    return !shift->is_mobile;
}

sub is_pc {
    my $self = shift;
    return (not $self->is_mobile and
            not $self->is_iphone and
            not $self->is_android and
            not $self->is_ipad and
            not $self->is_dsi and
            not $self->is_3ds and
            not $self->is_wii);
}

# Nintendo DSi browser (!= Ugomemo Theater)
sub is_dsi {
    my $self = shift;
    return index($self->user_agent, 'Nintendo DSi') != -1;
}

sub is_3ds {
    my $self = shift;
    return index($self->user_agent, 'Nintendo 3DS') != -1;
}

sub is_wii {
    my $self = shift;
    return index($self->user_agent, 'Nintendo Wii') != -1;
}

sub is_iphone {
    my $self = shift;
    my $ua = $self->user_agent;
    return (index($ua, 'iPhone') != -1 or index($ua, 'iPod') != -1);
}

sub is_ipad {
    my $self = shift;
    return index($self->user_agent, 'iPad') != -1;
}

sub is_android {
    my $self = shift;
    return index($self->user_agent, 'Android') != -1;
}

sub is_smartphone {
    my $self = shift;
    return ($self->is_iphone or $self->is_android);
}

sub is_hatena_star {
    my $self = shift;
    return index($self->user_agent, 'Hatena Star UserAgent') != -1;
}

# タッチ系デバイス (use_touch_version とは違うよ!)
sub is_touch_device {
    my $self = shift;
    return ($self->is_smartphone or
            $self->is_dsi or
            $self->is_3ds or
            $self->is_ipad);
}

sub is_tv_device {
    my $self = shift;
    return $self->is_wii;
}

# Don't support Flash by nature
sub no_flash {
    my $self = shift;
    return $self->is_iphone || $self->is_dsi || $self->is_3ds || $self->is_ipad;
}

# Has native support of canvas
sub has_canvas {
    my $self = shift;
    return 0 if $self->is_mobile;
    return 0 if $self->is_ie;
    return 1;
}

# モバイル版をデフォルトとするべき (うごメモはてな、カラースターショッ
# プなど)
sub use_mobile_version {
    my $self = shift;
    return ($self->is_mobile or $self->is_smartphone or $self->is_dsi or $self->is_3ds);
}

# スマートフォン版をデフォルトとするべき (はてなココ、はてなブックマー
# クなど)
sub use_touch_version {
    my $self = shift;
    return ($self->is_smartphone or $self->is_dsi or $self->is_3ds);
}

sub AUTOLOAD {
    my $method = our $AUTOLOAD;
    $method =~ s/.*:://o;
    no strict 'refs';
    *{$AUTOLOAD} = sub {
        my $self = shift;
        $self->browser->can($method) or return;
        return $self->browser->$method
    };
    goto &$AUTOLOAD;
}

sub DESTROY {}

1;
