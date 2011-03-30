#!perl
use Test::More qw/no_plan/;

{
    package test::Browser;
    use base qw(Ridge::Browser);

    sub new {
        my $class = shift;
        my %args = @_;
        my $self = $class->SUPER::new(delete $args{user_agent});
        return $self;
    }
}

sub ng ($;$) { ok !$_[0], $_[1] }

{
    my $b = test::Browser->new(user_agent => 'DoCoMo/1.0/N503i/c10');
    ng $b->is_pc;
    ng $b->has_canvas;
    ng $b->is_smartphone;
    ok $b->use_mobile_version;
    ng $b->use_touch_version;
    ng $b->is_wii;
    ng $b->is_ipad;
    ng $b->is_touch_device;
    ng $b->is_tv_device;
}

{
    my $b = test::Browser->new(user_agent => '');
    ok !$b->is_dsi;
    
    $b = test::Browser->new(user_agent => 'Opera (Nintendo DSi)');
    ok $b->is_dsi;

    ng $b->is_pc;
    ok $b->has_canvas;
    ng $b->is_smartphone;
    ok $b->use_mobile_version;
    ok $b->use_touch_version;
    ng $b->is_wii;
    ng $b->is_ipad;
    ok $b->is_touch_device;
    ng $b->is_tv_device;
    ok $b->no_flash;
}

{
    my $b = test::Browser->new(user_agent => 'Opera (Nintendo Wii)');
    ng $b->is_dsi;
    ng $b->is_pc;
    ok $b->has_canvas;
    ng $b->is_smartphone;
    ng $b->use_mobile_version;
    ng $b->use_touch_version;
    ok $b->is_wii;
    ng $b->is_ipad;
    ng $b->is_touch_device;
    ok $b->is_tv_device;
    ng $b->no_flash;
}

{
    my $b = test::Browser->new(user_agent => '');
    ok !$b->is_iphone;
    
    $b = test::Browser->new(user_agent => 'Mozilla/5.0 (iPhone; U; CPU like Mac OS X; ja-jp) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/3A110a Safari/419.3');
    ok $b->is_iphone;
    ng $b->is_pc;
    ok $b->has_canvas;
    ok $b->is_smartphone;
    ok $b->use_mobile_version;
    ok $b->use_touch_version;
    ng $b->is_wii;
    ng $b->is_ipad;
    ok $b->is_touch_device;
    ng $b->is_tv_device;
    ok $b->no_flash;
}

{
    my $b = test::Browser->new(user_agent => '');
    ok !$b->is_android;
    
    $b = test::Browser->new(user_agent => 'Mozilla/5.0 (iPod Touch; U; CPU like Mac OS X; ja-jp) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/3A110a Safari/419.3');
    ok $b->is_iphone;
    
    ng $b->is_pc;
    ok $b->has_canvas;
    ok $b->is_smartphone;
    ok $b->use_mobile_version;
    ok $b->use_touch_version;
    ng $b->is_wii;
    ng $b->is_ipad;
    ok $b->is_touch_device;
    ng $b->is_tv_device;
    ok $b->no_flash;
}

{
    my $b = test::Browser->new(user_agent => '');
    ok !$b->is_android;
    
    $b = test::Browser->new(user_agent => 'Mozilla/5.0 (iPad; U; CPU like Mac OS X; ja-jp) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/3A110a Safari/419.3');
    ng $b->is_iphone;

    ng $b->is_pc;
    ok $b->has_canvas;
    ng $b->is_smartphone;
    ng $b->use_mobile_version;
    ng $b->use_touch_version;
    ng $b->is_wii;
    ok $b->is_ipad;
    ok $b->is_touch_device;
    ng $b->is_tv_device;
    ok $b->no_flash;
}

{
    my $b = test::Browser->new(user_agent => '');
    ok !$b->is_android;
    
    # Simulator
    $b = test::Browser->new(user_agent => 'Mozilla/5.0 (Linux; U; Android 1.0; en-us; generic) AppleWebKit/525.10+ (KHTML, like Gecko) Version/3.0.4 Mobile Safari/523.12.2');
    ok $b->is_android;
    ng $b->is_pc;
    ok $b->has_canvas;
    ok $b->is_smartphone;
    ok $b->use_mobile_version;
    ok $b->use_touch_version;
    ng $b->is_wii;
    ng $b->is_ipad;
    ok $b->is_touch_device;
    ng $b->is_tv_device;
    
    # T-mobile G1
    $b = test::Browser->new(user_agent => 'Mozilla/5.0 (Linux; U; Android 1.0; en-us; dream) AppleWebKit/525.10+ (KHTML, like Gecko) Version/3.0.4 Mobile Safari/523.12.2');
    ok $b->is_android;
    ng $b->is_pc;
    ok $b->has_canvas;
    ok $b->is_smartphone;
    ok $b->use_mobile_version;
    ok $b->use_touch_version;
    ng $b->is_wii;
    ng $b->is_ipad;
    ok $b->is_touch_device;
    ng $b->is_tv_device;
}

