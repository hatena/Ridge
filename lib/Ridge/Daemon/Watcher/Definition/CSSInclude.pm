package Ridge::Daemon::Watcher::Definition::CSSInclude;
use strict;
use warnings;
use Ridge::Daemon::Watcher::Definition;
push our @ISA, qw(Ridge::Daemon::Watcher::Definition);
use Path::Class qw(file);

__PACKAGE__->mk_classdata(default_directory => 'static/css');
__PACKAGE__->mk_classdata(default_file_regexp => qr{(?:/|^)[A-Za-z0-9_-]+\.css\.(?:in|part)$});

__PACKAGE__->mk_classdata(default_onupdate => sub {
    my ($self, $file) = @_;

    eval {
        my @file;
        if ($file =~ /\.part$/) {
            my $part = $file->slurp; # bytes
            $part =~ s{\@-hatena-included-by\s*'([^']+)'\s*;}{
                push @file, $file->dir->file($1);
            }ge;
        } else {
            push @file, $file;
        }

        for my $file (@file) {
            my $new_file_name = $file;
            $new_file_name =~ s/\.in$// or next;
        
            my $content = $file->slurp; # bytes
            $content =~ s{\@-hatena-include\s*'([^']+)'\s*;}{
                my $included = $file->dir->file($1);
                $included->slurp; # bytes
            }ge;

            warn "CSSInclude: $file -> $new_file_name\n";
            file($new_file_name)->openw->print($content); # bytes
        }

        1;
    } or warn $@;
});

1;
