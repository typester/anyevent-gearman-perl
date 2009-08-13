package AnyEvent::Gearman::Connection;
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

sub process_packet { die "Must override" }

__PACKAGE__->meta->make_immutable;
