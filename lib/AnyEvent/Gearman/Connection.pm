package AnyEvent::Gearman::Connection;
use Any::Moose;
use Scalar::Util 'weaken';

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

has context => (
    is       => 'rw',
    isa      => 'Object',
    weak_ref => 1,
);

has handler => (
    is      => 'rw',
    isa     => 'Maybe[AnyEvent::Handle]',
    clearer => 'clear_handler',
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

has _con_guard => (
    is  => 'rw',
    isa => 'Object',
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

    my $g = tcp_connect $self->_host, $self->_port, sub {
        my ($fh) = @_;

        if ($fh) {
            my $handle = AnyEvent::Handle->new(
                fh       => $fh,
                on_read  => sub { $self->process_packet },
                on_error => sub {
                    my @undone = @{ $self->_need_handle },
                                 values %{ $self->_job_handles };
                    $_->event('on_fail') for @undone;

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
            $self->mark_dead;
            $_->() for map { $_->[1] } @{ $self->on_connect_callbacks };
        }

        $self->on_connect_callbacks( [] );
    };

    weaken $self;
    $self->_con_guard($g);

    $self;
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
    $self->clear_handler;
}

sub alive {
    my ($self) = @_;
    $self->dead_time <= time;
}

sub process_packet {
    my $self   = shift;
    my $handle = $self->handler;

    $handle->unshift_read(chunk => 4, sub {
        unless ($_[1] eq "\0RES") {
            die qq[invalid packet: $_[1]"];
        }

        $_[0]->unshift_read( chunk => 8, sub {
            my ($type, $len)   = unpack 'NN', $_[1];
            my $packet_handler = $self->can("process_packet_$type");

            unless ($packet_handler) {
                # Ignore unimplement packet
                $_[0]->unshift_read( chunk => $len, sub {} ) if $len;
                return;
            }

            $packet_handler->( $self, $len );
        });
    });
    weaken $self;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

AnyEvent::Gearman::Connection - common base class to handle connection

=head1 SEE ALSO

L<AnyEvent::Gearman>, L<AnyEvent::Gearman::Client>, L<AnyEvent::Gearman::Worker>.

=head1 METHODS

=head2 connect

=head2 connected

=head2 add_on_ready

=head2 mark_dead

=head2 alive

=head2 process_packet

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
