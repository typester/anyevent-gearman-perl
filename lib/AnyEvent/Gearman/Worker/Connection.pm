package AnyEvent::Gearman::Worker::Connection;
use Any::Moose;
use Scalar::Util 'weaken';
require bytes;

use AnyEvent::Gearman::Constants;
use AnyEvent::Gearman::Job;

extends 'AnyEvent::Gearman::Connection';

has grabbing => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

no Any::Moose;

sub request {
    my ($self, $type, $args) = @_;
    $args ||= '';

    $self->add_on_ready(
        sub {
            $self->handler->push_write(
                "\0REQ" . pack('NN', $type, bytes::length($args)) . $args
            );
        },
        sub {
            warn sprintf 'Failed to send request to "%s": %s', $self->hostspec, $!;
        },
    );
    weaken $self;
}

sub register_function {
    my ($self, $func_name) = @_;

    my $prefix = $self->context->prefix;
    $func_name = "$prefix\t$func_name" if $prefix;

    $self->can_do($func_name);
    $self->grab_job unless $self->grabbing;
}

sub unregister_function {
    my ($self, $func_name) = @_;

    my $prefix = $self->context->prefix;
    $func_name = "$prefix\t$func_name" if $prefix;

    $self->cant_do($func_name);
}

sub can_do {
    my ($self, $func_name) = @_;
    $self->request(CAN_DO, $func_name);
}

sub cant_do {
    my ($self, $func_name) = @_;
    $self->request(CANT_DO, $func_name);
}

sub grab_job {
    my $self = shift;
    $self->grabbing(1);
    $self->request(GRAB_JOB);
}

sub pre_sleep {
    my $self = shift;
    $self->request(PRE_SLEEP);
}

sub process_packet_6 {          # NOOP
    my ($self, $len) = @_;
    $self->grab_job;
}

sub process_packet_10 {         # NO_JOB
    my ($self, $len) = @_;
    $self->grabbing(0);
    $self->pre_sleep;
}

sub process_packet_11 {         # JOB_ASSIGN
    my ($self, $len) = @_;
    my $handle = $self->handler;

    $self->grabbing(0);

    $handle->unshift_read( line => "\0", sub {
        my $job_handle = $_[1];
        $len -= bytes::length($job_handle) + 1;

        $_[0]->unshift_read( line => "\0", sub {
            my $function = $_[1];
            $len -= bytes::length($function) + 1;

            $_[0]->unshift_read( chunk => $len, sub {
                my $workload = $_[1];

                my $job = AnyEvent::Gearman::Job->new(
                    $function => $workload,
                    on_complete => sub {
                        my ($job, $result) = @_;
                        $self->request(WORK_COMPLETE, "$job_handle\0$result");
                        $self->grab_job();
                    },
                    on_data => sub {
                        my ($job, $data) = @_;
                        $self->request(WORK_DATA, "$job_handle\0$data");
                    },
                    on_fail => sub {
                        my ($job) = @_;
                        $self->request(WORK_FAIL, $job_handle);
                        $self->grab_job();
                    },
                    on_status => sub {
                        my ($job, $numerator, $denominator) = @_;
                        $self->request(
                            WORK_STATUS, "$job_handle\0$numerator\0$denominator"
                        );
                    },
                    on_warning => sub {
                        my ($job, $warning) = @_;
                        $self->request(WORK_WARNING, "$job_handle\0$warning");
                    },
                );
                $self->work( $job );
            });
        });
    });
    weaken $self;
}

sub work {
    my ($self, $job) = @_;

    my $cb = $self->context->functions->{ $job->function } or return;
    $cb->($job);
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

AnyEvent::Gearman::Worker::Connection - connection class for worker

=head1 METHODS

=head2 request

=head2 register_function

=head2 unregister_function

=head2 can_do

=head2 cant_do

=head2 grab_job

=head2 pre_sleep

=head2 work

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
