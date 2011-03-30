package Ridge::Handler::Apache2;
use strict;
use warnings;

use Apache2::RequestIO();
use Apache2::RequestRec();
use Apache2::Response();
use Apache2::Const -compile => qw(:common :http);
use UNIVERSAL::require;
use HTTP::Status ();
use IO::File;
use Fcntl qw(:flock);
use Carp qw/confess/;
use POSIX qw(strftime);

# for preloading
use Ridge::Request::Apache2 ();

my $STATUS2CONST = {
    HTTP::Status::RC_OK                    => Apache2::Const::OK,
    HTTP::Status::RC_CREATED               => Apache2::Const::HTTP_CREATED,
    HTTP::Status::RC_MOVED_PERMANENTLY     => Apache2::Const::HTTP_MOVED_PERMANENTLY,
    HTTP::Status::RC_FOUND                 => Apache2::Const::HTTP_MOVED_TEMPORARILY,
    HTTP::Status::RC_NOT_MODIFIED          => Apache2::Const::HTTP_NOT_MODIFIED,
    HTTP::Status::RC_BAD_REQUEST           => Apache2::Const::HTTP_BAD_REQUEST,
    HTTP::Status::RC_UNAUTHORIZED          => Apache2::Const::AUTH_REQUIRED,
    HTTP::Status::RC_FORBIDDEN             => Apache2::Const::HTTP_FORBIDDEN,
    HTTP::Status::RC_NOT_FOUND             => Apache2::Const::NOT_FOUND,
    HTTP::Status::RC_INTERNAL_SERVER_ERROR => Apache2::Const::SERVER_ERROR,
};

sub handler : method {
    my ($class, $r) = @_;

    $ENV{RIDGE_NAMESPACE} or
        die "Couldn't find an environment variable 'RIDGE_NAMESPACE' in httpd.conf.";

    my $res;
    if ($ENV{RIDGE_SHOW_EXCEPTION} || $ENV{RIDGE_EXCEPTION_FILEOUT}) {
        # so fast
        eval {
            $res = $ENV{RIDGE_NAMESPACE}->process({ request_driver => $r });
        };
        my $error_tmp = $@;
        if (my $e = Ridge::Exception->caught) {
            $res = $e->as_response;
            if ($ENV{RIDGE_EXCEPTION_FILEOUT}) {
                # save exception stacktrace
                my $timestr = strftime "%Y/%m/%d %H:%M:%S", localtime;
                my $unparsed_uri = $r->unparsed_uri();
                my $mes = sprintf "----------- [ERROR: %s] ------------\n%s\n\n%s\n", $timestr, $unparsed_uri, $e->as_string_pretty;
                my $file = $ENV{RIDGE_EXCEPTION_FILEOUT};
                my $io = (-f $file) ? IO::File->new($file, 'a+') : IO::File->new($file, 'w+');
                flock($io, LOCK_EX);
                $io->print($mes);
                flock($io, LOCK_UN);
                $io->close;
            }
            if ( !$ENV{RIDGE_SHOW_EXCEPTION} ) {
                confess $error_tmp;
            }
        }
        if (!$res || !$res->headers) {
            confess $error_tmp;
        }
    } else {
        $res = $ENV{RIDGE_NAMESPACE}->process({ request_driver => $r });
    }

    my $h = $res->headers;
    my $headers_out = $res->code >= 300 ? 'err_headers_out' : 'headers_out';
    for my $name ($h->header_field_names) {
        next if $name =~ /^Content-(Length|Type)$/i;
        my @values = $h->header($name);
        $r->$headers_out->add($name => $_) for @values;
    }

    $r->status($res->code);
    if ($res->content_type) {
        my $type = join ';', $res->content_type;
        $r->content_type($type);
    }

    if (my $length = $res->content_length) {
        $r->set_content_length($length);
    }

    $r->print($res->content || '');

    if (defined (my $const = $STATUS2CONST->{$res->code})) {
        return $const;
    } else {
        return $res->code;
    }
}

1;
