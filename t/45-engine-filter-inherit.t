use strict;
use warnings;
use Test::More;
use Test::Deep qw(cmp_deeply noclass);

# ロード順の保証のため eval してます

eval <<'__t_Engine__';
    package t::Engine;
    use Ridge::Engine -Base;

    before_filter
        ':all' => 'base_filter';

    after_filter
        'mobile' => 'some_mobile_filter';

    sub base_filter { 1 }

    sub default : Public {
    }

    $INC{'t/Engine.pm'} = __FILE__;
__t_Engine__


eval <<'__t_Engine_A__';
    package t::Engine::A;
    use t::Engine -Base;

    before_filter
        default => 'before_default',
        foo => 'before_foo';

    sub before_default { 1 }

    sub before_foo { 1 }

__t_Engine_A__

fail, diag $@ if $@;

isnt +t::Engine->_before_filter, +t::Engine::A->_before_filter, '親子エンジンで同じフィルタコンテナをみていない';

cmp_deeply +t::Engine->_before_filter->{filters}->{default},
           [ noclass({ filter => 'base_filter' }) ],
           't::Engine#default';

cmp_deeply +t::Engine::A->_before_filter->{filters}->{default},
           [ noclass({ filter => 'base_filter' }), noclass({ filter => 'before_default' }) ],
           't::Engine::A#default';

cmp_deeply +t::Engine::A->_before_filter->{filters}->{foo},
           [ noclass({ filter => 'before_foo' }) ],
           't::Engine::A#foo';

cmp_deeply +t::Engine::A->_after_filter->{filters}->{mobile},
           [ noclass({ filter => 'some_mobile_filter' }) ],
           't::Engine::A#mobile';

done_testing;
