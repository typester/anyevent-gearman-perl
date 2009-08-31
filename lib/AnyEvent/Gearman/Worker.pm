package AnyEvent::Gearman::Worker;
use Any::Moose;

use AnyEvent::Gearman::Types;
use AnyEvent::Gearman::Worker::Connection;

extends any_moose('::Object'), 'Object::Event';

has job_servers => (
    is       => 'ro',
    isa      => 'ArrayRef[AnyEvent::Gearman::Worker::Connection]',
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
