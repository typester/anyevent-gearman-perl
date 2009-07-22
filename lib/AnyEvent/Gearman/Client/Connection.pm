package AnyEvent::Gearman::Client::Connection;
use Any::Moose;

use AnyEvent::Socket;
use AnyEvent::Handle;

has hostspec => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has _host => (
    is  => 'rw',
    isa => 'Str',
);

has _port => (
    is  => 'rw',
    isa => 'Int | Str',
);

has handler => (
    is  => 'rw',
    isa => 'Maybe[AnyEvent::Handle]',
);

has on_connect_callbacks => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has dead_time => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has _need_handle => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has _job_handles => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

no Any::Moose;

sub BUILD {
    my $self = shift;

    # parse hostspec
    my ($host, $service) = parse_hostport $self->hostspec;
    unless (defined $host) {
        $host    = $self->hostspec;
        $service = 4730;
    }

    unless (defined($host) && defined($service)) {
        die sprintf('Failed to parse hostspec: "%s"', $self->hostspec);
    }

    $self->_host( $host );
    $self->_port( $service );
}

sub connect {
    my ($self) = @_;

    # already connected
    return if $self->handler;

    my $w; $w = tcp_connect $self->_host, $self->_port, sub {
        my ($fh) = @_; scalar $w;

        if ($fh) {
            my $handle = AnyEvent::Handle->new(
                fh       => $fh,
                on_read  => sub { $self->process_packet },
                on_error => sub {
                    $self->_need_handle([]);
                    $self->_job_handles({});
                    $self->mark_dead;
                },
            );
            $self->handler( $handle );

            $_->() for map { $_->[0] } @{ $self->on_connect_callbacks };
        }
        else {
            warn sprintf("Connection failed: %s", $!);
            undef $w;
            $self->mark_dead;
            $_->() for map { $_->[1] } @{ $self->on_connect_callbacks };
        }

        $self->on_connect_callbacks( [] );
    };
}

sub connected {
    !!shift->handler;
}

sub add_task {
    my ($self, $task, $on_complete, $on_error) = @_;

    $self->add_on_ready(
        sub {
            push @{ $self->_need_handle }, $task;
            $self->handler->push_write( $task->pack );
        },
        $on_error,
    );
}

sub add_on_ready {
    my ($self, $cb, $eb) = @_;

    if ($self->connected) {
        $cb->();
    }
    else {
        push @{ $self->on_connect_callbacks }, [ $cb, $eb ];
        $self->connect;
    }
}

sub mark_dead {
    my ($self) = @_;
    $self->dead_time( time + 10 );
}

sub alive {
    my ($self) = @_;
    $self->dead_time <= time;
}

sub process_packet {
    my $self = shift;

    my $handle = $self->handler;

    $handle->unshift_read( chunk => 4, sub { # \0RES
        unless ($_[1] eq "\0RES") {
            die qq[invalid packet: $_[1]"];
        }

        $handle->unshift_read( chunk => 8, sub {
            my ($type, $len)   = unpack('NN', $_[1]);
            my $packet_handler = $self->can("process_packet_$type");

            unless ($packet_handler) {
                # Ignore unimplement packet
                $handle->unshift_read( chunk => $len, sub {} ) if $len;
                return;
            }

            $packet_handler->( $self, $len );
        });
    });
}

sub process_work {              # common handler for WORK_*
    my ($self, $len, $cb) = @_;
    my $handle = $self->handler;

    $handle->unshift_read( line => "\0", sub {
        my $job_handle = $_[1];
        $len -= length($job_handle) + 1;

        $handle->unshift_read( chunk => $len, sub {
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

        $self->_job_handles->{ $job_handle } = $task;
        $task->event( 'on_created' );
    });
}

sub process_packet_12 {         # WORK_STATUS
    my ($self, $len) = @_;
    my $handle = $self->handler;

    $handle->unshift_read( line => "\0", sub {
        my $job_handle = $_[1];
        $len -= length($_[1]) + 1;

        $handle->unshift_read( line => "\0", sub {
            my $numerator = $_[1];
            $len -= length($_[1]) + 1;

            $handle->unshift_read( chunk => $len, sub {
                my $denominator = $_[1];

                my $task = $self->_job_handles->{ $job_handle } or return;
                $task->event( on_status => $numerator, $denominator );
            });
        });
     });
}

sub process_packet_13 {         # WORK_COMPLETE
    my ($self) = @_;

    push @_, sub {
        my ($job_handle, $data) = @_;

        my $task = delete $self->_job_handles->{ $job_handle } or return;
        $task->event( on_complete => $data );
    };

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
}

sub process_packet_25 {         # WORK_EXCEPTION
    my ($self) = @_;

    push @_, sub {
        my ($job_handle, $data) = @_;
        my $task = $self->_job_handles->{ $job_handle } or return;
        $task->event( on_exception => $data );
    };

    goto \&process_work;
}

sub process_packet_28 {         # WORK_DATA
    my ($self) = @_;

    push @_, sub {
        my ($job_handle, $data) = @_;

        my $task = $self->_job_handles->{ $job_handle } or return;
        $task->event( on_data => $data );
    };

    goto \&process_work;
}

sub process_packet_29 {         # WORK_WARNING
    my ($self) = @_;

    push @_, sub {
        my ($job_handle, $data) = @_;
        my $task = $self->_job_handles->{ $job_handle } or return;

        $task->event( on_warning => $data );
    };

    goto \&process_work;
}

__PACKAGE__->meta->make_immutable;

