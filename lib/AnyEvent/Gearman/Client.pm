package AnyEvent::Gearman::Client;
use Any::Moose;

use AnyEvent::Gearman::Types;
use AnyEvent::Gearman::Task;
use AnyEvent::Gearman::Client::Connection;

has job_servers => (
    is       => 'rw',
    isa      => 'AnyEvent::Gearman::Client::Connections',
    required => 1,
    coerce   => 1,
);

has prefix => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

no Any::Moose;

sub add_task {
    my $self = shift;
    
    return $self->_add_task('', @_)
}

sub add_task_bg {
    my $self = shift;
    
    return $self->_add_task('bg', @_)
}

sub _add_task {
    my ($self, $type, $function, $workload, %cb) = @_;

    $function = $self->prefix . "\t" . $function
        if $self->prefix;

    my $task = AnyEvent::Gearman::Task->new( $function, $workload, %cb );

    my $retry; ($retry = sub {
        my @js = grep { $_->alive } @{ $self->job_servers };

        unless (@js) {
            $task->event( on_fail => 'no server available' );
            undef $retry;
            return;
        }

        # TODO: hashed server selector
        my $js = @js[int rand @js];
        $js->add_task(
            $task,

            # task added successfully
            sub {
                undef $retry;
            },

            # on error
            $retry,
            
            # task type
            $type,
        );
    })->();

    $task;
}

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords Str namespace

=head1 NAME

AnyEvent::Gearman::Client - Gearman client for AnyEvent application

=head1 SYNOPSIS

    use AnyEvent::Gearman::Client;
    
    # create greaman client
    my $gearman = AnyEvent::Gearman::Client->new(
        job_servers => ['127.0.0.1', '192.168.0.1:123'],
    );
    
    # start job
    $gearman->add_task(
        $function => $workload,
        on_complete => sub {
            my $res = $_[1];
        },
        on_fail => sub {
            # job failed
        },
    );
    
    # start background job
    $gearman->add_task_bg(
        $function => $workload,
    );
    

=head1 DESCRIPTION

This is Gearman client module for AnyEvent applications.

=head1 SEE ALSO

L<Gearman::Client::Async>, this module provides same functionality for L<Danga::Socket> applications.

=head1 METHODS

=head2 new(%options)

Create gearman client object.

    my $gearman = AnyEvent::Gearman::Client->new(
        job_servers => ['127.0.0.1', '192.168.0.1:123'],
    );

Available options are:

=over 4

=item job_servers => 'ArrayRef',

List of gearman servers. 'host:port' or just 'host' formats are allowed.
In latter case, gearman default port 4730 will be used.

You should set at least one job_server.

=item prefix => 'Str',

Sets the namespace / prefix for the function names. This is useful for sharing job servers between different applications or different instances of the same application (different development sandboxes for example).

The namespace is currently implemented as a simple tab separated concatenation of the prefix and the function name.

=back

=head2 add_task($function, $workload, %callbacks)

Start new job and wait results in C<%callbacks>

    $gearman->add_task(
        $function => $workload,
        on_complete => sub {
            my $result = $_[1],
        },
        on_fail => sub {
            # job failled
        },
    );

C<$function> is a worker function name, and C<$workload> is a data that will be passed to worker.

C<%callbacks> is set of callbacks called by job events. Available callbacks are:

=over 4

=item on_complete => $cb->($self, $result)

Called when the job is completed. C<$result> is some results data which is set by C<< $job->complete($result) >> in worker.

=item on_fail => $cb->($self, $reason)

Called when the job is failed. C<$reason> is empty if its threw by worker. I don't know why but gearman spec say so. Considering to use C<on_warning> below for some failing notify.

=item on_warning => $cb->($self, $warning)

Called when C<< $job->warning($warning) >> called in worker.

=item on_data => $cb->($self, $data)

Called when C<< $job->data($data) >> called in worker.

=item on_status => $cb->($self, $numerator, $denominator)

Called when C<< $job->status($numerator, $denominator) >> called in worker

=item on_created => $cb->($self)

Called when the servers reports that the task was created successfully.
Updates the Task object with the server assigned C<job_handle>.

=back

You should to set C<on_complete> and C<on_fail> at least.


=head2 add_task_bg($function, $workload, %callbacks)

Starts a new background job. The parameters are the same as
L<add_task($function, $workload, %callbacks)|add_task()>, but the only
callback that is called is C<on_created>.

    $gearman->add_task_bg(
        $function => $workload,
        on_created => sub {
            my ($task) = @_;
        },
    );


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
