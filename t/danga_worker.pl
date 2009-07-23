#!/usr/bin/perl

use strict;
use Gearman::Worker;
use Getopt::Long;
my $opt_js;
GetOptions('s=s' => \$opt_js);

my $worker = Gearman::Worker->new;
$worker->job_servers(split(/,/, $opt_js));

$worker->register_function("reverse" => sub {
    my $job = shift;
    my $arg = $job->arg;

    reverse $arg;
});

$worker->register_function("sum" => sub {
    my $job = shift;
    my $arg = $job->arg;

    my $res = 0;
    $res += $_ for split /\s+/, $arg;

    $res;
});

$worker->work while 1;

