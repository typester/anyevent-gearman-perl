package AnyEvent::Gearman::Client::Connection;
use Any::Moose;
use Scalar::Util 'weaken';

extends 'AnyEvent::Gearman::Connection';

no Any::Moose;

sub add_task {
    my ($self, $task, $on_complete, $on_error, $type) = @_;

    $self->add_on_ready(
        sub {
            push @{ $self->_need_handle }, $task;
            $self->handler->push_write( $task->pack_req($type) );
        },
        $on_error,
    );
    weaken($self);

    return;
}

sub process_work {              # common handler for WORK_*
    my ($self, $len, $cb) = @_;
    my $handle = $self->handler;

    $handle->unshift_read( line => "\0", sub {
        my $job_handle = $_[1];
        $len -= length($job_handle) + 1;

        $_[0]->unshift_read( chunk => $len, sub {
            $cb->( $job_handle, $_[1] );
        });
    });
}

sub process_packet_8 {          # JOB_CREATED
    my ($self, $len) = @_;

    my $handle = $self->handler;

    $handle->unshift_read( chunk => $len, sub {
        my $job_handle = $_[1];
        my $task = shift @{ $self->_need_handle } or return;

        $task->job_handle($job_handle);
        $self->_job_handles->{ $job_handle } = $task;
        $task->event( 'on_created' );
    });
    weaken $self;
}

sub process_packet_12 {         # WORK_STATUS
    my ($self, $len) = @_;
    my $handle = $self->handler;

    $handle->unshift_read( line => "\0", sub {
        my $job_handle = $_[1];
        $len -= length($_[1]) + 1;

        $_[0]->unshift_read( line => "\0", sub {
            my $numerator = $_[1];
            $len -= length($_[1]) + 1;

            $_[0]->unshift_read( chunk => $len, sub {
                my $denominator = $_[1];

                my $task = $self->_job_handles->{ $job_handle } or return;
                $task->event( on_status => $numerator, $denominator );
            });
        });
    });
    weaken $self;
}

sub process_packet_13 {         # WORK_COMPLETE
    my ($self) = @_;

    push @_, sub {
        my ($job_handle, $data) = @_;

        my $task = delete $self->_job_handles->{ $job_handle } or return;
        $task->event( on_complete => $data );
    };
    weaken $self;

    goto \&process_work;
}

sub process_packet_14 {         # WORK_FAIL
    my ($self, $len) = @_;
    my $handle = $self->handler;

    $handle->unshift_read( chunk => $len, sub {
        my $job_handle = $_[1];
        my $task       = delete $self->_job_handles->{ $job_handle } or return;
        $task->event('on_fail');
    });
    weaken $self;
}

sub process_packet_25 {         # WORK_EXCEPTION
    my ($self) = @_;

    push @_, sub {
        my ($job_handle, $data) = @_;
        my $task = $self->_job_handles->{ $job_handle } or return;
        $task->event( on_exception => $data );
    };
    Scalar::Util::weaken($self);

    goto \&process_work;
}

sub process_packet_28 {         # WORK_DATA
    my ($self) = @_;

    push @_, sub {
        my ($job_handle, $data) = @_;

        my $task = $self->_job_handles->{ $job_handle } or return;
        $task->event( on_data => $data );
    };
    weaken $self;

    goto \&process_work;
}

sub process_packet_29 {         # WORK_WARNING
    my ($self) = @_;

    push @_, sub {
        my ($job_handle, $data) = @_;
        my $task = $self->_job_handles->{ $job_handle } or return;

        $task->event( on_warning => $data );
    };
    weaken $self;

    goto \&process_work;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

AnyEvent::Gearman::Client::Connection - connection class for client

=head1 METHODS

=head2 add_task

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

