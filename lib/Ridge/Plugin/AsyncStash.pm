package Ridge::Plugin::AsyncStash;
use strict;
use warnings;
use base qw/Ridge::Plugin/;
require UNIVERSAL::require;

our $fallback;
BEGIN {
    eval {
        Coro->use or die;
        $ENV{DISABLE_ASYNC} && die;
        Coro::Event->use or die; # libevent backend for mod_perl
        Coro::LWP->use or die;
    };
    if ($@) {
        warn "failed to load library";
        warn "	fallback to synced stash;";
        $fallback = 1;
    }
}

sub initialize {
    my ($plugin, $r) = @_;
}


# $block は非同期実行されるものでなければならない
# Coro::LWP をロードしているので LWP リクエストは勝手に非同期化される
# それ以外の場合明示的に非同期コールしなければ意味がないので要注意
sub async_stash : Method {
    my ($plugin, $r, $name, $block) = @_;
    if ($fallback) {
        if ($block) {
            my $async = $block->();
            $r->stash->param($name => $async);
        } else {
            $r->stash->param($name);
        }
    } else {
        if ($block) {
            my $async = async {
                $block->();
            };
            cede; # one pass to async block
            $r->stash->param($name => $async);
        } else {
            # warn "get async stash: $name";
            $r->stash->param($name)->join;
        }
    }
}

1;
