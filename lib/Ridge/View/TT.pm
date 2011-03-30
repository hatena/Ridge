package Ridge::View::TT;
use strict;
use warnings;
use base qw/Ridge::View::Base/;
use Class::Trigger;

use Carp;
use CLASS;
use Template;
use Template::Stash::ForceUTF8;
use Template::Provider::Encoding;
use Path::Class qw/dir/;

use UNIVERSAL::require;
use Ridge::Exceptions;

CLASS->use_template(1);
CLASS->type('html');

my $Template;

sub configure {
    my ($self, $config) = @_;
    my $ttconfig = {
        INCLUDE_PATH   => [ dir($config->param('root'), 'templates') ],
        ABSOLUTE       => 1,
    };

    if ($config->param('charset') eq 'utf-8' or $config->param('charset') eq 'utf8') {
        # Template::Stash::ForceUTF8->require or die $@;
        # Template::Provider::Encoding->require or die $@;
        $ttconfig->{STASH} = Template::Stash::ForceUTF8->new;
        $Template::Config::PROVIDER = 'Template::Provider::Encoding';
    }

    for my $key (keys %{$config->param('View::TT') || {}}) {
        $ttconfig->{$key} = $config->param('View::TT')->{$key};
    }

    unless ($Template) {
        $Template = Template->new($ttconfig)
            or Ridge::Exception::TemplateError->throw(error => $Template::Error);
    }
    $self;
}

sub process {
    my ($self, $r, $filename) = @_;

    {
        $self->call_trigger(before_process => $Template);
        my $retval = $Template->process(
            $filename,
            {
                r     => $r,
                ridge => $r,
                %{$r->stash->to_hash},
            },
            \my $output,
        );
        $self->call_trigger(after_process => $Template);

        unless ($retval) {
            my $exception = ($Template->error->type eq 'file' and $Template->error->info =~ m/((not found$)|(no providers for template prefix))/)
                ? 'Ridge::Exception::TemplateNotFound'
                : 'Ridge::Exception::TemplateError';
            $exception->throw(error => sprintf "Error from Template Toolkit: %s", $Template->error);
        }

        return $output;
    }
}

1;
