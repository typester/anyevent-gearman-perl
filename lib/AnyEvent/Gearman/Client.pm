package AnyEvent::Gearman::Client;
use Any::Moose;

our $VERSION = '0.01';

use AnyEvent::Gearman::Client::Types;
use AnyEvent::Gearman::Client::Task;
use AnyEvent::Gearman::Client::Connection;

has job_servers => (
    is       => 'rw',
    isa      => 'ArrayRef[AnyEvent::Gearman::Client::Connection]',
    required => 1,
    coerce   => 1,
);

no Any::Moose;

sub add_task {
    my ($self, $function, $workload, %cb) = @_;

    my $task = AnyEvent::Gearman::Client::Task->new( $function, $workload, %cb );

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
        );
    })->();
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

AnyEvent::Gearman::Client - Module abstract (<= 44 characters) goes here

=head1 SYNOPSIS

    use AnyEvent::Gearman::Client;
    
    my $cv = AnyEvent->condvar;
    
    my $gearman = AnyEvent::Gearman::Client->new(
        job_servers => ['127.0.0.1'],
    );
    
    $gearman->add_task( 'reverse', 'Hello World!',
        on_complete => sub {
            $cv->send( $_[1] );
        },
        on_fail => sub {
            $cv->send;
        },
    );
    
    my $result = $cv->recv;

=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
