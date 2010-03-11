#!/usr/bin/perl

use strict;
use Gearman::Worker;
use Getopt::Long;
GetOptions(
    \my %opt,
    qw/servers=s prefix=s/,
);

my $worker = Gearman::Worker->new;
$worker->job_servers(split(/,/, $opt{servers}));
$worker->prefix($opt{prefix}) if $opt{prefix};

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

