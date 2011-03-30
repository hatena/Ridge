package Ridge::Daemon::Watcher;
use strict;
use warnings;
use base qw/Ridge::Object/;
use File::Modified;
use File::Find;
use CLASS;
use Path::Class qw/file dir/;
use Ridge;
use Ridge::Util qw/logger/;

CLASS->mk_accessors(qw/root directory modified watch_list defs/);

sub _init {
    my $self = shift;
    my $watch_list = $self->_modules;
    $self->watch_list($watch_list);
    $self->modified(
        File::Modified->new(
            method => 'mtime',
            files  => [ keys %{$watch_list} ],
        )
    );
}

sub watch {
    my $self = shift;

    my @changes;
    my @changed_files;

    eval { @changes = $self->modified->changed };
    if ($@) {

        # File::Modified will die if a file is deleted.
        my ($deleted_file) = $@ =~ /stat '(.+)'/;
        push @changed_files, $deleted_file || 'unknown file';
    }

    if (@changes) {
        # update all mtime information
        $self->modified->update;

        # check if any files were changed
        @changed_files = grep { -f $_ } @changes;

        # Test modified pm's
        for my $file (@changed_files) {
            if ($file =~ /\.pm$/) {
                if ( my $error = $self->_test($file) ) {
                    $file = file($file)->relative($self->root) if $self->root;
                    my @errorstr = [];
                    push @errorstr, ('*' x 80);
                    push @errorstr, qq/File "$file" was modified but it has someting wrong.\n/;
                    push @errorstr, $error;
                    push @errorstr, ('*' x 80);
                    logger->error(join "\n", @errorstr);
                    return;
                }
            } else {
                $file = file($file);
                $file = $file->relative($self->root) if $self->root;
                for my $def (@{$self->defs or []}) {
                    $def->process_onbeforeupdate($file);
                }
            }
        }
    }

    return @changed_files;
}

sub _test {
    my ( $self, $file ) = @_;

    delete $INC{$file};
    local $SIG{__WARN__} = sub { };

    open my $olderr, '>&STDERR';
    open STDERR, '>', File::Spec->devnull;
    eval "require '$file'";
    open STDERR, '>&', $olderr;

    return ($@) ? $@ : 0;
}

sub _modules {
    my $self = shift;
    my %list;

    my $directory = $self->directory or die "No directory specified";
    $self->directory->recurse(callback => sub {
        my $dirent = shift;
        $dirent->is_dir and return;
        return unless $dirent =~ /(?<!_flymake)\.pm$/;
        return unless -f $dirent;
        $list{$dirent->absolute} = 1;
    });

    for my $def (@{$self->defs || []}) {
        $def->abs_dir->recurse(callback => sub {
            my $dirent = shift;
            return if $dirent->is_dir;
            return unless $def->file_match($dirent);
            return unless -f $dirent;
            $list{$dirent->absolute} = 1;
        });
    }

    \%list;
}

1;
