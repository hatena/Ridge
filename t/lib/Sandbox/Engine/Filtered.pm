package Sandbox::Engine::Filtered;
use strict;
use warnings;
use Sandbox::Engine -Base;
use HTTP::Status;
use Ridge::Exceptions;

before_filter
    default                => [
        sub { shift->res->content_type('foo/bar'); 1 },
        sub { shift->res->content('filtered'); 1 },
    ],
    method                 => [ qw/filter_method/ ],
    private_method         => [ qw/_private_filter/ ],
    class                  => [ qw/Sandbox::Filter::Test/],
    'first, second, third' => [ sub { shift->res->content('filtered'); 1 } ],
    ':except except'       => [ sub { shift->res->header('X-Filtered-Except' => 1); 1 } ],
    redirect               => sub { return shift->res->redirect('/') },
    assert                 => [ sub { Ridge::Exception::RequestError->throw(code => RC_FORBIDDEN) } ],
    chain_stop             => [
        sub { shift->res->content_type('foo/bar'); 1 },
        sub { 0 },
        sub { shift->res->content_type('my/god'); 1 },
    ],
    goto_view              => [
        sub {
            my $r = shift;
            $r->res->content('viewed');
            return $r->goto_view;
        },
    ]
    ;

after_filter
    after_filtered => [ sub {
        my $r = shift;
        my $content = $r->res->content;
        $content = uc $content;
        $r->res->content($content);
        1;
    }]
    ;


sub filter_method {
    my ($self, $r) = @_;
    $r->res->content('filtered by filter_method()');
    1;
}

sub _private_filter {
    my ($self, $r) = @_;
    $r->res->content('filtered by _private_filter()');
    1;
}

sub default : Public {}
sub method : Public {}
sub first : Public {}
sub second : Public {}
sub third : Public {}
sub class : Public {}
sub private_method : Public {}
sub assert : Public {}
sub chain_stop : Public {}
sub except : Public {
    my ($self, $r) = @_;
    $r->res->content_as_text('except');
}

sub redirect : Public {
    my ($self, $r) = @_;
    die 'assert';
}

sub goto_view : Public {
    my ($self, $r) = @_;
    die 'assert';
}

sub after_filtered : Public {
    my ($self, $r) = @_;
    $r->res->content_as_text('aiueo');
}

1;
