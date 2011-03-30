package Ridge::Plugin::Cat;
use strict;
use warnings;
use base qw/Ridge::Plugin Class::Data::Inheritable/;
use Cache::Memcached;

__PACKAGE__->mk_classdata(cache => new Cache::Memcached {
    servers => [ qw/127.0.0.1:11211/ ],
});

sub cat : Method {
    my ($plugin, $r, $base, @files) = @_;
    my $out;
    for (@files) {
        my $file = $r->path_to('static', $base, $_);
        if (my $content = $plugin->cache->get($file->stringify)) {
            $out .= sprintf "%s\n", $content->{body};
        } else {
            $file->stat or next;
            my $body = $file->slurp;
            $plugin->cache->set(
                $file->stringify => {
                    mtime => $file->stat->mtime,
                    body  => $body,
                }
            );
            $out .= $body;
        }
    }
    $out;
}

1;
