package Ridge::Exception;
use strict;
use warnings;
use Exception::Class;
use base qw/Exception::Class::Base/;
use HTTP::Response;
use Template;
use HTTP::Status;
use CLASS;
use IO::File;
use Exporter::Lite;

sub html_escape ($) {
    my $text = shift;
    for ($text) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/"/&quot;/g; #"
    }
    return $text;
}

sub print_context {
    my ($file, $linenum) = @_;
    my $code;
    if (-f $file) {
        my $start = $linenum - 3;
        my $end   = $linenum + 3;
        $start = $start < 1 ? 1 : $start;
        if (my $fh = IO::File->new($file, 'r')) {
            my $cur_line = 0;
            while (my $line = <$fh>) {
                ++$cur_line;
                last if $cur_line > $end;
                next if $cur_line < $start;
                my @tag = $cur_line == $linenum ? ('<div class="line">', '</div>') : ('', '');
                $code .= sprintf(
                    '%s%5d: %s%s',
                    $tag[0], $cur_line, html_escape $line, $tag[1],
                );
            }
            $fh->close;
        }
    }
    $code;
}

my $template;

sub _template {
    return $template if $template;
    local $/;
    my $fh = \*DATA;
    $template = <$fh>;
}

sub as_html {
    my $self = shift;
    my $vars = {
        class   => CLASS,
        desc    => $self->message,
        context => \&print_context,
    };
    my @stacktrace = $self->trace->frames;
    shift @stacktrace;
    $vars->{stacktrace} = \@stacktrace;
    $_->{args_arrayref} = $_->{args} for @stacktrace;
    my $tt = Template->new;
    $tt->process(\_template(), $vars, \my $output) or die $tt->error;
    $output;
}

sub as_string_pretty {
    my $self = shift;
    join "\n", grep { ! ( m/^(POE::|Ridge::)/ || m/Ridge\/Daemon\.pm/ || m/eval\s.*(Ridge\.pm|\/POE\/)/ ) } 
       $self->as_string, split "\n", $self->trace->as_string;
}

sub as_response {
    my $self = shift;
    my $res = Ridge::Response->new;
    $res->content_type('text/html');
    $res->code(RC_INTERNAL_SERVER_ERROR);
    $res->content($self->as_html);
    $res->content_length(length $res->content);
    $res;
}

1;

__DATA__
<html>
<head>
<title>500 Internal Server Error</title>
<style type="text/css">
body {
  font-family: 'Trebuchet MS', Arial;
  background-color: #fff;
}

h1 {
  font-size: 120%;
  border: 1px solid #c99;
  color: #fff;
  background-color: #c00;
  padding: 5px;
}

h2 {
  font-size: 110%;
  margin-left: 3px;
}

pre {
  padding: 20px;
  margin: 10px;
  border: 1px solid #ccc;
  border-color: #9c9;
  color: #060;
  word-wrap: break-word;
  white-space: -moz-pre-wrap;
  background-color: #E2F9E3;
  font-size: 80%;
}

pre.error {
  margin-left: 6px;
  color: #000;
  background-color: fff;
  border: none;
  line-height: 140%;
  font-size: 90%;
  margin: 10px;
  padding: 0;
}

div.line {
  font-weight: bold;
  background-color: #c2F9c3;
}

address {
  text-align: right;
  font-family: Arial;
  font-size: 90%;
}
</style>
</head>
<body>
<h1>500 Internal Server Error</h1>
<h2>Errors and Stacktrace</h2>

<pre class="error">[% desc | html %]</pre>

<table width="100%">
  <tr>
    <th>package</th>
    <th>line</th>
    <th>file</th>
  </tr>
  [% FOR stack IN stacktrace %]
  <tr>
    <td>[% stack.package | html %]</td>
    <td>[% stack.line | html %]</td>
    <td>[% stack.filename | html %]</td>
  </tr>
  <tr>
    <td colspan=3>... calls <code>[% stack.subroutine | html %]</code></td>
  </tr>
  [% IF stack.hasargs %]
    <tr>
      <td colspan=3>
        ... with arguments:
        <ol start=0>
          [% FOREACH arg IN stack.args_arrayref %]
            <li><code>[% arg | html %]</code></li>
          [% END # arg %]
        </ol>
      </td>
    </tr>
  [% END # hasargs %]
  <tr>
    <td colspan="3">
      <pre>[% context(stack.filename, stack.line) %]</pre>
    </td>
  </tr>
  [% END %]
</table>
</body>
</html>
