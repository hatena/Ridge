#!perl
use strict;
use warnings;

package MyTestSuite::Filter;
use Test::Base::Filter -Base;
use FindBin::libs;
use Sandbox;
use Ridge::Exceptions;

use HTTP::Request::Common;
use HTTP::Message::PSGI;

sub code {
    my $url = shift;
    my $retval;
    eval {
        my $res = Sandbox->process(HTTP::Request->new(GET => $url)->to_psgi);
        $res = res_from_psgi $res;
        $retval = $res->code;
    };
    if (my $e = Ridge::Exception->caught) {
        warn $e;
    }
    $retval;
}

package MyTestSuite;
use Test::Base -Base;

__END__
===
--- input code: http://d.hatena.ne.jp
--- expect: 200

=== /
--- input code: http://d.hatena.ne.jp/
--- expect: 200

=== /index.redirect
--- input code: http://d.hatena.ne.jp/index.redirect
--- expect: 302

=== /index.moved
--- input code: http://d.hatena.ne.jp/index.moved
--- expect: 301

=== /index.no_action
--- input code: http://d.hatena.ne.jp/index.no_action
--- expect: 200

=== /index.no_template
--- input code: http://d.hatena.ne.jp/index.no_template
--- expect: 200

=== /index.alter_template
--- input code: http://d.hatena.ne.jp/index.alter_template
--- expect: 200

=== /notfound
--- input code: http://d.hatena.ne.jp/notfound
--- expect: 404

=== /noengine
--- input code: http://d.hatena.ne.jp/noengine
--- expect: 200

=== /config
--- input code: http://d.hatena.ne.jp/config
--- expect: 200

=== /config/design
--- input code: http://d.hatena.ne.jp/config/design
--- expect: 200

=== /config/design.update
--- input code: http://d.hatena.ne.jp/config/design
--- expect: 200

=== /config/notfound
--- input code: http://d.hatena.ne.jp/config/notfound
--- expect: 404

=== /index.json
--- input code: http://d.hatena.ne.jp/index.json
--- expect: 200

=== /index.yaml
--- input code: http://d.hatena.ne.jp/index.yaml
--- expect: 200

=== /redirect
--- input code: http://d.hatena.ne.jp/redirect
--- expect: 302

=== /hoge.get_denied
--- input code: http://d.hatena.ne.jp/hoge.get_denied
--- expect: 405
