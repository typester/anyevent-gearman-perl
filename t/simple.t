use Test::Base;
use Test::TCP;
use AnyEvent::Gearman::Client;

eval q{
        use Gearman::Worker;
        use Gearman::Server;
    };
if ($@) {
    plan skip_all
        => "Gearman::Worker and Gearman::Server are required to run this test";
}

plan tests => 2;

my $port = empty_port;

sub run_tests {
    my $client = AnyEvent::Gearman::Client->new(
        job_servers => ['127.0.0.1:' . $port],
    );

    {
        my $cv = AnyEvent->condvar;

        $client->add_task(
            'reverse', 'Hello World!',
            on_complete => sub {
                $cv->send($_[1]);
            },
            on_fail => sub {
                $cv->send('fail');
            },
        );
        is($cv->recv, reverse('Hello World!'), 'reverse ok');
    }

    {
        my $cv = AnyEvent->condvar;

        my $task = $client->add_task(
            'sum', '3 5',
            on_fail => sub {
                $cv->send('fail');
            },
        );
        $task->reg_cb( on_complete => sub { $cv->send($_[1]) } );

        is($cv->recv, 8, 'sum ok');
    }
}

my $child = fork;
if (!defined $child) {
    die "fork failed: $!";
}
elsif ($child == 0) {
    my $server = Gearman::Server->new( port => $port );
    $server->start_worker("$^X t/danga_worker.pl -s 127.0.0.1:$port");
    Danga::Socket->EventLoop;
}
else {
    END { kill 9, $child if $child }
}

sleep 1;

run_tests;
