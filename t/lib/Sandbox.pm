package Sandbox;
use strict;
use warnings;
use base qw/Ridge/;
use FindBin;
use Path::Class;

# __PACKAGE__->configure;

__PACKAGE__->configure({
    plugins         => [qw/Hello Cat Debug XFramework/],
    # plugins         => [qw/Hello Debug XFramework/],
    root            => $FindBin::Bin,
    static_path     => ['^/images', '^/js', '^/css'],
    'Plugin::Hello' => { message => 'World' },
    'URI'           => '',
    cookie_domain   => '.hatena.ne.jp',
    app_config      => {
        default => {
            uri => 'http://sandbox.hatena.com/',
            dsn => 'dbi:mysql:sandbox;host=127.0.0.1',
        },
        devel   => {
            uri => 'http://dev.sandbox.hatena.com/',
        },
    }
});

1;

__END__
