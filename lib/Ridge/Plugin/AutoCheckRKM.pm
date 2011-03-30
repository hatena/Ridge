package Ridge::Plugin::AutoCheckRKM;
use strict;
use warnings;
use base qw/Class::Component::Plugin/;

my $loaded = {};

sub check_rkm : Method {
    my ($self, $r, $new) = @_;
    $r->{_check_rkm} = $new if defined $new;
    1;
}

sub initialize {
    my ($self, $r) = @_;

    # 全ての Engine に Filter を追加していく
    # Class::Trigger は object に対して add_trigger すると
    # そのインスタンスだけ有効になる
    $r->add_trigger('before_dispatch', sub {
        my ($r, $engine) = @_;
        my $pkg = ref $engine;
        return if $loaded->{$pkg};

        no strict 'refs';
        *{"$pkg\::before_filter"}->(
            ":all" => [
                sub {
                    my ($r, @args) = @_;

                    if (defined $r->{_check_rkm} && !$r->{_check_rkm}) {
                        return 1;
                    } else {
                        return $self->_check_rkm($r, @args);
                    }
                }
            ]
        );
#        *{"$pkg\::after_filter"}->(
#            ":all" => [
#                sub {
#                    my ($r, @args) = @_;
#                    $self->_append_rkm($r, @args);
#                }
#            ]
#        );
        $loaded->{$pkg} = 1;
    });

}

sub _check_rkm {
    my ($self, $r) = @_;

    if (uc $r->req->request_method eq 'POST') {
        my $rkm = $r->req->param('rkm') || '';

        if ($r->user && $rkm eq $r->user->rkm) {
            return 1;
        } else {
            $r->res->header("X-Ridge-Reason" => "AUTO CHECK RKM FAILED");
            return 0;
        }
    }

    return 1;
}

sub _append_rkm {
    my ($self, $r) = @_;
    # 自動的に RKM 付与を行うと、
    # JSONP API を作るときなどに RKM が漏洩する可能性があり危険
    # content_type はチェックするにしても、そういった危険性はどっちにしろあるため
    # 自動付与の機能はつけるべきではない。
    #
    # RKM 自動付与のリスク >>> 開発者の手間軽減
}

sub stash {
    my $self = shift;
    @_ ? $self->{_stash} = shift : $self->{_stash};
}

sub cleanup {
    shift->{_stash} = undef;
}

1;
