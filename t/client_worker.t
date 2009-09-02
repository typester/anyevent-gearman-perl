use Test::Base;
use Test::TCP;

use AnyEvent::Gearman::Client;
use AnyEvent::Gearman::Worker;

eval q{
        use Gearman::Worker;
        use Gearman::Server;
    };
if ($@) {
    plan skip_all
        => "Gearman::Worker and Gearman::Server are required to run this test";
}

plan 'no_plan';

my $port = empty_port;

sub run_tests {
    my $server_hostspec = '127.0.0.1:' . $port;

    my $client = AnyEvent::Gearman::Client->new(
        job_servers => [$server_hostspec],
    );

    my $worker = AnyEvent::Gearman::Worker->new(
        job_servers => [$server_hostspec],
    );
    $worker->register_function( reverse => sub {
        my $job = shift;
        my $res = reverse $job->workload;
        $job->complete($res);
    });

    my $cv = AnyEvent->condvar;
    $client->add_task(
        reverse => 'Hello!',
        on_complete => sub {
            $cv->send($_[1]);
        },
        on_fail => sub {
            $cv->send('fail');
        },
    );

    is $cv->recv, reverse('Hello!'), 'reverse ok';
}

my $child = fork;
if (!defined $child) {
    die "fork failed: $!";
}
elsif ($child == 0) {
    my $server = Gearman::Server->new( port => $port );
    Danga::Socket->EventLoop;
    exit;
}
else {
    END { kill 9, $child if $child }
}

run_tests;

