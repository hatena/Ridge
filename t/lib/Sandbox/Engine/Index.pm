package Sandbox::Engine::Index;
use strict;
use warnings;
use Sandbox::Engine -Base;
use Encode;

sub default : Public {
    my ($self, $r) = @_;
    $r->view->available(qw/html json yaml/);
    $r->stash->param(hello => '世界');
}

sub private {}

sub js_test : Public {
    my ($self, $r) = @_;
    $r->view->available(qw/html json/);
    $r->stash->expose_param(['hoge']);
    $r->stash->param(
        hoge        => 'foo',
        private_var => 'barbar'
    );
}

sub hello : Public {
    my ($self, $r) = @_;
    $r->res->content_as_text($r->hello || 0);
}

sub bye : Public {
    my ($self, $r) = @_;
    $r->res->content_as_text($r->bye);
}

sub redirect : Public {
    my ($self, $r) = @_;
    $r->res->redirect('http://d.hatena.ne.jp/');
}

sub moved : Public {
    my ($self, $r) = @_;
    $r->res->redirect_permanently('http://d.hatena.ne.jp/');
}

sub no_template : Public {
    my ($self, $r) = @_;
}

sub alter_template : Public {
    my ($self, $r) = @_;
    $r->view->filename('index.html');
}

sub euc : Public {
    my ($self, $r) = @_;
    $r->res->charset('euc-jp');
    $r->view->filename('index.html');
}

sub utf8 : Public {
    my ($self, $r) = @_;
    my $string = decode('utf-8', "こんにちは、世界");
    $r->res->content($string);
}

sub non_utf8 : Public {
    my ($self, $r) = @_;
    my $string = "こんにちは、世界";
    $r->res->content($string);
}

sub error : Public {
    my $self = shift;
    $self->no_such_method;
}

sub app_uri : Public {
    my ($self, $r) = @_;
    $r->res->content_as_text($r->app_config->param('uri'));
}

sub cookie : Public {
    my ($self, $r) = @_;
    $r->res->cookie(-name => 'foo', -value => 'bar');
    $r->res->cookie(-name => 'aaa', -value => 'bbb', -domain => '.g.hatena.ne.jp');
    $r->res->content("check baked cookies please.");
}

1;
