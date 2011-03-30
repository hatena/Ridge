package Ridge::AttrHandler;
use strict;
use warnings;
use base qw/Class::Data::Inheritable/;
use List::MoreUtils qw/any/;
use Class::Inspector;

BEGIN {
    __PACKAGE__->mk_classdata(__attr_cache => {});
}

sub MODIFY_CODE_ATTRIBUTES {
    my ($class, $code, @attrs) = @_;
    __PACKAGE__->__attr_cache->{$code} = [ @attrs ];
    return ();
}

sub attr_of {
    my ($class, $method) = @_;
    my $code = $class->can($method) or return;
    my $attrs = $class->__attr_cache->{$code} or return;
    wantarray ? @$attrs : $attrs;
}

sub is_public {
    my ($self, $method) = @_;
    my @attrs = $self->attr_of($method) or return;
    # any { $_ eq 'Public' } @attrs;
    any { $_ eq 'public' or $_ eq 'Public' } @attrs;
}

sub public_actions {
    my $class = ref $_[0] ? ref shift : shift;
    my $methods = Class::Inspector->methods($class, 'public') or return;
    my @public_methods = grep { $class->is_public($_) } @$methods;
    wantarray ? @public_methods : \@public_methods;
}

1;

