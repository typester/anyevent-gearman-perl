package AnyEvent::Gearman::Worker::Connection;
use Any::Moose;
use Scalar::Util 'weaken';
require bytes;

use AnyEvent::Gearman::Constants;

extends 'AnyEvent::Gearman::Connection';

has context => (
    is       => 'rw',
    isa      => 'AnyEvent::Gearman::Worker',
    weak_ref => 1,
);

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

                my $task = AnyEvent::Gearman::Task->new(
                    $function, $workload,
                    on_complete => sub {
                        my ($task, $result) = @_;
                        $self->request(WORK_COMPLETE, "$job_handle\0$result");
                    },
                    on_data => sub {
                        my ($task, $data) = @_;
                        $self->request(WORK_DATA, "$job_handle\0$data");
                    },
                    on_fail => sub {
                        my ($task) = @_;
                        $self->request(WORK_FAIL, $job_handle);
                    },
                    on_status => sub {
                        my ($task, $numerator, $denominator) = @_;
                        $self->request(
                            WORK_STATUS, "$job_handle\0$numerator\0$denominator"
                        );
                    },
                    on_warning => sub {
                        my ($task, $warning) = @_;
                        $self->request(WORK_WARNING, "$job_handle\0$warning");
                    },
                );
                $self->work( $task );
            });
        });
    });
    weaken $self;
}

sub work {
    my ($self, $task) = @_;

    my $cb = $self->context->functions->{ $task->function } or return;
    $cb->($task);
}

__PACKAGE__->meta->make_immutable;
