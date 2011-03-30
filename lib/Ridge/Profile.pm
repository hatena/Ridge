package Ridge::Profile;
use strict;
use warnings;
use base qw/Class::Data::Inheritable/;

__PACKAGE__->mk_classdata('result' => {});

sub init {
    my $class = shift;
    $class->result({});
}

sub profile {
    my $class = shift;
    my $name = shift;
    my $type = shift || 'start';
    my ($package) = caller(1);
    # warn "$package $name $type";
    my $timeofday = Time::HiRes::gettimeofday();
    $class->result->{start_time} ||= $timeofday;
    my $level;
    if ($package =~ /^Template/) {
        # template
        $level = ($name =~ /(::)/g) + 2;
        $name  = join '::', 'template', $name;
    } else {
        # module
        my $base_level = ($name =~ /(::)/g);
        $name = join '::', $package, $name;
        my ($i, $known);
        for (1..10) {
            my ($package) = caller($_);
            $known->{$package}++ and next;
            $i++;
            if ($package eq 'Ridge') {
                $level = $i;
                last;
            }
        }
        $level += $base_level;
    }
    $level or return;
    my $prev_name = $class->result->{current_name}->{$level} || '';
    if ($class->result->{item}->{$name} && $type eq 'start') {
        # 同じルーチンが複数回呼ばれた場合にsuffix追加
        $name .= '+';
    }
    #warn "$prev_name > $name : $type : $level";
    unless ($class->result->{item}->{$name}) {
        $class->result->{item}->{$name} = {
            name  => $name,
            level => $level,
        };
        push @{$class->result->{names}}, $name;
    }
    if ($type eq 'end') {
        $class->result->{item}->{$name}->{end} = $timeofday;
    } elsif ($prev_name && $prev_name ne $name) {
        $class->result->{item}->{$prev_name}->{end} = $timeofday;
        $class->result->{item}->{$name}->{start} = $timeofday;
    } else {
        $class->result->{item}->{$name}->{start} = $timeofday;
    }
    $class->result->{current_name}->{$level} = $name;
    return; # テンプレートからも呼ばれるので空を返す(ｷﾘｯ
}

sub profile_report {
    my $class = shift;
    my $total = int((Time::HiRes::gettimeofday - $class->result->{start_time}) * 1000);
    my $report = sprintf("|[Profile] total : %s msec\n", $total);
    #use Data::Dumper; warn Dumper $class->result;
    for my $name (@{$class->result->{names} || []}) {
        my $item = $class->result->{item}->{$name};
        $item->{start} or next;
        $item->{end} or next;
        my $second = int(($item->{end} - $item->{start}) * 1000);
        $report .= sprintf("|%s %s : %s msec \n", ('-' x $item->{level}), $name, $second);
    }
    return $report;
}

1;
