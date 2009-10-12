#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use AnyEvent::Gearman;

## Test the usage of constants as arguments
lives_ok sub {
    my $worker = gearman_worker '127.0.0.1';
    $worker->register_function(test => sub {});
};

lives_ok sub {
    my $client = gearman_client '127.0.0.1';
    $client->add_task(test => 'live!');
};

done_testing();
