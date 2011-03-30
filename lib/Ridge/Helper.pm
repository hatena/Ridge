package Ridge::Helper;
use strict;
use warnings;
use base qw/Ridge::Object/;
use Path::Class;
use UNIVERSAL::require;
use File::Slurp qw/slurp/;
use CLASS;
use Template;
use IO::Prompt;
use Config;
use Cwd;
use Pod::Usage;

CLASS->mk_accessors(qw/myname argv namespace root startperl/);

sub new {
    my ($class, $args) = @_;
    my $helper = join '::', 'Ridge', 'Helper', ucfirst shift @{$args->{argv}};
    $helper->require;

    if ($@ and $@ =~ m/Can\'t locate .*? in \@INC/) {
        pod2usage("$0: No such helper\n");
    } elsif ($@) {
        die $@;
    }

    my $self = bless $args, $helper;
    for ($self->root) {
        s!::!-!g;
        $self->root($_);
    }

    $self->myname($helper);
    $self->startperl($Config{startperl});
    $self;
}

sub run {
    my $self = shift;
    $self->create;
}

sub get_template {
    my $self = shift;
    my $template;
    {
        no strict 'refs';
        $template = slurp(\*{join '::', $self->myname, 'DATA'});
    }
    $template;
}

sub mk_dir {
    my ($self, @path) = @_;
    my $dir = dir($self->root, @path);
    return if $dir->stat;
    $dir->mkpath or die $!;
    STDOUT->print(sprintf "created directory \"%s\"\n", $dir->relative(getcwd));
}

sub render_file {
    my ($self, @path) = @_;
    my $tt = Template->new;
    $tt->process(\$self->get_template, { h => $self }, \my $output);
    my $file = file($self->root, @path);

    unless ($file->dir->stat) {
        $file->dir->mkpath or die $!;
        STDOUT->print(sprintf "created directory \"%s\"\n", $file->dir->relative(getcwd));
    }

    return if $file->stat and not prompt(
        sprintf("%s already exists. Overwrite? [y/n] ", $file->relative(getcwd)), '-yes_no'
    );

    my $fh = $file->openw or die $!;
    $fh->print($output);
    $fh->close;
    STDOUT->print(sprintf "created \"%s\"\n", $file->relative(getcwd));
}

sub render_module {
    my ($self, $type, $module) = @_;
    my $namespace = $self->namespace;
    s/::/\//g for ($namespace, $module);
    if ($type) {
        $self->render_file(
            'lib',
            $namespace,
            $type,
            sprintf("%s.pm", $module),
        );
    } else {
        $self->render_file('lib', sprintf("%s.pm", $module));
    }
}

1;
