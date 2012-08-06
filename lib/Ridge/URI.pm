package Ridge::URI;
use Parse::RecDescent;

use strict;
use warnings;
use Carp;
use base qw/URI::http/;
use URI::Escape;
use Ridge::Flow;

#$::RD_TRACE = 1;
#$::RD_HINT = 1;

my $DefaultSyntax = q(
    uri          : scheme '://' host path
    scheme       : 'https' | 'http'
    host         : /[\w\-.:]+/
    path         : default_path
    default_path : path_segment(s) action(?) view(?) {$return = {
        path_segments => $item[1],
        action => $item[2]->[0] || '',
        view => $item[3]->[0] || '',
        params => {},
    }}
    path_segment : '/' /[\w-]*/ { $item[2] || '' }
    action       : view(?) <reject: $item[1]->[0]> /\.(\w+)/ { $1 }
    view         : /\.(html|json|yaml)$/ { $1 }
);

my $ParseResults = {};
my $Parser = Parse::RecDescent->new($DefaultSyntax);
my $Filter;

sub replace_syntax {
    my ($class, $syntax) = @_;
    $syntax or croak 'usage: Ridge::URI->replace_syntax($syntax)';
    $Parser->Replace($syntax);
}

sub extend_syntax {
    my ($class, $syntax) = @_;
    $syntax or croak 'usage: Ridge::URI->extend_syntax($syntax)';
    $Parser->Extend($syntax);
}

sub new {
    my ($class, $uri) = @_;
    $uri = URI->new($uri) unless ref $uri;
    $uri = bless $uri, $class;
    $Filter->($uri) if $Filter;
    my @authorities = map { s/\s//g; $_ } split( ',', uri_unescape( $uri->authority ) );
    $uri->authority( shift @authorities );
    $uri->_parse;
    $uri;
}

sub new_abs {
    my ($class, @args) = @_;
    my $uri = URI->new_abs(@args);
    $uri = bless $uri, $class;
    $Filter->($uri) if $Filter;
    $uri->_parse;
    $uri;
}

sub _parse {
    my $self = shift;
    (my $uri = $self->as_string) =~ s/\?.*$//o;
    $ParseResults = {
        %{$Parser->uri($uri) || {}},
        %{$ParseResults || {}},
    };
}

sub filter {
    my ($class, $code) = @_;
    $Filter = $code if $code and ref $code eq 'CODE';
    $Filter;
}

sub action {
    $ParseResults->{action};
}

sub path_segments {
    $ParseResults->{path_segments};
}

sub view {
    $ParseResults->{view};
}

sub param {
    my ($self, $attr, $value) = @_;
    $value ? $ParseResults->{params}->{$attr} = $value
           : $ParseResults->{params}->{$attr};
}

sub root {
    my $uri = shift->clone;
    $uri->path_query('/');
    $uri;
}

sub to_flow {
    my $self = shift;
    Ridge::Flow->new({
        path_segments => $self->path_segments || [],
        action        => $self->action || '',
        view          => $self->view || '',
        device        => $self->device || '',
    });
}

sub as_uri {
    my $self = shift;
    return URI->new($self . '');
}

sub DESTROY {
    undef $ParseResults;
}

sub device {
    my ($self) = @_;
    $self->param('device');
}

1;

=head1 NAME

Ridge::URI

=head1 SYNOPSIS

  # You can parse uri easily and get parameters to dispatch request
  # to your Ridge::Engines.
  my $uri = Ridge::URI->new('http://d.hatena.ne.jp/entries.rss');
  print $uri->host; # 'd.hatena.ne.jp'
  print $uri->path; # '/entries.rss'
  print $uri->path_segments; # ['entries']
  print $uri->view; # 'rss'

  # Replace default syntax with Hatena style user page.
  Ridge::URI->replace_syntax(q(
    path : user_path | default_path
    user_path : '/' user_name default_path {
        $return = $item[3];
        $return->{params}->{user_name} = $item[2];
    }
    user_name : /[A-Za-z][\w\-]{1,13}[A-Za-z0-9]/
  ));
  my $uri2 = Ridge::URI->new('http://d.hatena.ne.jp/naoya/entry.create');
  print $uri->param('user_name'); # 'naoya'
  print $uri->path_segments; # ['entry']
  print $uri->action; # 'create'

=head1 METHODS

=item replace_syntax

Replace default path syntax. Please specify your original syntax in
L<Parse::RecDescent> format.
Additional syntax will be replaced internally using Parse::RecDescent->Replace
method.

  Ridge::URI->replace_syntax(q(
    path : user_path | default_path
    user_path : '/' user_name default_path {
        $return = $item[3];
        $return->{params}->{user_name} = $item[2];
    }
    user_name : /[A-Za-z][\w\-]{1,13}[A-Za-z0-9]/
  ));

=item param

Get parameters in params attribute. You should use params hash reference in 
path's return value to store extracted parameters from uri.
