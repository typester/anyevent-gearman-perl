package AnyEvent::Gearman;
use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.09';

our @EXPORT = qw/gearman_client gearman_worker/;

use AnyEvent::Gearman::Client;
use AnyEvent::Gearman::Worker;

sub gearman_client {
    AnyEvent::Gearman::Client->new(
        job_servers => [@_],
    );
}

sub gearman_worker {
    AnyEvent::Gearman::Worker->new(
        job_servers => [@_],
    );
}

1;

__END__

=head1 NAME

AnyEvent::Gearman - Asynchronous Gearman client/worker module for AnyEvent applications

=head1 SYNOPSIS

    use AnyEvent::Gearman;

Client:

    my $client = gearman_client '127.0.0.1', '192.168.0.1:123';
    
    $client->add_task(
        $function => $workload,
        on_complete => sub {
            my $result = $_[1];
            # ...
        },
        on_fail => sub {
            # job failed
        },
    );

Worker:

    my $worker = gearman_worker '127.0.0.1', '192.168.0.1:123';
    
    $worker->register_function(
        reverse => sub {
            my $job = shift;
            my $res = reverse $job->workload;
            $job->complete($res);
        },
    );

=head1 DESCRIPTION

AnyEvent::Gearman is a module set of client/worker modules for Gearman for AnyEvent applications.

This module provides some shortcuts for L<AnyEvent::Gearman::Client> and L<AnyEvent::Gearman::Worker>.
Please read these modules documentation for more details.

=head1 EXPORTED FUNCTIONS

=head2 gearman_client( @job_servers );

Create a gearman client.

    my $client = gearman_client '127.0.0.1', '192.168.0.1:123';

This is shortcut for:

    my $client = AnyEvent::Gearman::Client->new(
        job_servers => ['127.0.0.1', '192.168.0.1:123'],
    );

See L<AnyEvent::Gearman::Client> for more detail.

=head2 gearman_worker( @job_servers );

Create a gearman worker.

    my $worker = gearman_worker '127.0.0.1', '192.168.0.1:123';

This is shortcut for:

    my $worker = AnyEvent::Gearman::Worker->new(
        job_servers => ['127.0.0.1', '192.168.0.1:123'],
    );

See L<AnyEvent::Gearman::Worker> for more detail.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

Pedro Melo <melo@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
