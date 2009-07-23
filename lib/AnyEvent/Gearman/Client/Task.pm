package AnyEvent::Gearman::Client::Task;
use Any::Moose;
use AnyEvent::Gearman::Client::SharedObject 'obj';

extends any_moose('::Object'), 'Object::Event';

has function => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has workload => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has unique => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        obj('ug')->create_str;
    },
);

has [qw/on_created on_data on_complete on_fail on_status on_warning on_exception/] => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub { sub {} },
);

no Any::Moose;

sub BUILDARGS {
    my ($self, $function, $workload, %params) = @_;

    return {
        function => $function,
        workload => $workload,
        %params,
    }
}

sub BUILD {
    my $self = shift;

    $self->reg_cb(
        on_created   => $self->on_created,
        on_data      => $self->on_data,
        on_complete  => $self->on_complete,
        on_fail      => $self->on_fail,
        on_status    => $self->on_status,
        on_warning   => $self->on_warning,
        on_exception => $self->on_exception,
    );
}

sub pack {
    my $self = shift;

    my $data = $self->function . "\0"
             . $self->unique . "\0"
             . $self->workload;

    "\0REQ" . pack('NN', 7, length($data)) . $data;
}

__PACKAGE__->meta->make_immutable;
