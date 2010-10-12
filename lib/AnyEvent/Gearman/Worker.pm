package AnyEvent::Gearman::Worker;
use Any::Moose;

use AnyEvent::Gearman::Types;
use AnyEvent::Gearman::Worker::Connection;

BEGIN { do { eval q[use MouseX::Foreign; 1] or die $@ } if any_moose eq 'Mouse' }

extends any_moose('::Object'), 'Object::Event';

has job_servers => (
    is       => 'ro',
    isa      => 'AnyEvent::Gearman::Worker::Connections',
    required => 1,
    coerce   => 1,
);

has prefix => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has functions => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

no Any::Moose;

sub register_function {
    my ($self, $func_name, $code) = @_;

    die qq[Function "$func_name" already registered]
        if $self->functions->{ $func_name };

    for my $js (@{ $self->job_servers }) {
        $js->context($self) unless $js->context;
        $js->register_function( $func_name );
    }

    $self->functions->{ $func_name } = $code;
}

sub unregister_function {
    my ($self, $func_name) = @_;

    for my $js (@{ $self->job_servers }) {
        $js->context($self) unless $js->context;
        $js->unregister_function( $func_name );
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords unregister

=head1 NAME

AnyEvent::Gearman::Worker - Gearman worker for AnyEvent application

=head1 SYNOPSIS

    use AnyEvent::Gearman::Worker;
    
    # create gearman worker
    my $worker = AnyEvent::Gearman::Worker->new(
        job_servers => ['127.0.0.1', '192.168.0.1:123'],
    );
    
    # add worker function
    $worker->register_function( reverse => sub {
        my $job = shift;
        my $res = reverse $job->workload;
        $job->complete($res);
    });

=head1 DESCRIPTION

This is Gearman worker module for AnyEvent applications.

=head1 METHODS

=head2 new(%options)

Create gearman worker object.

    my $worker = AnyEvent::Gearman::Worker->new(
        job_servers => ['127.0.0.1', '192.168.0.1:123'],
    );

Options are:

=over 4

=item job_servers => 'ArrayRef'

List of gearman servers. 'host:port' or just 'host' formats are allowed.
In latter case, gearman default port 4730 will be used.

You should set at least one job_server.

=back

=head2 register_function( $function_name, $subref )

Register worker function.

    $worker->register_function( reverse => sub {
        my $job = shift;
        my $res = reverse $job->workload;
        $job->complete($res);
    });

C<$function_name> is function name string to register.

C<$subref> is worker CodeRef that will be executed when the worker received a request for this function. And it will be passed a L<AnyEvent::Gearman::Job> object representing the job that has been received by the worker.

NOTE: Unlike L<Gearman::Worker>, this module ignore C<$subref>'s return value.
So you should call either C<< $job->complete >> or C<< $job->fail >> at least.

This is because this module stands L<AnyEvent>'s asynchronous way, and this way more flexible in AnyEvent world.

For example:

    $worker->register_function( reverse => sub {
        my $job = shift;

        my $t; $t = AnyEvent->timer(
            after => 10,
            cb    => sub {
                undef $t;
                $job->complete('done!');
            },
        );
    });

This is simplest and meaningless codes but you can write worker process with AnyEvent way. This is asynchronous worker.

=head2 unregister_function( $function_name )

Unregister worker function, notifying to server that this worker no longer handle C<$function_name>.

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
