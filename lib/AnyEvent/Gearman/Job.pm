package AnyEvent::Gearman::Job;
use Any::Moose;

extends 'AnyEvent::Gearman::Task';

no Any::Moose;

sub complete {
    my ($self, $result) = @_;
    $self->event( on_complete => $result );
}

sub data {
    my ($self, $data) = @_;
    $self->event( on_data => $data );
}

sub fail {
    my ($self) = @_;
    $self->event('on_fail');
}

sub status {
    my ($self, $numerator, $denominator) = @_;
    $self->event( on_status => $numerator, $denominator );
}

sub warning {
    my ($self, $warning) = @_;
    $self->event( on_warning => $warning );
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

AnyEvent::Gearman::Job - gearman job

=head1 SYNOPSIS

    $job->complete($result);
    $job->data($data);
    $job->fail;
    $job->status($numerator, $denominator);
    $job->warning($warning);

=head1 METHODS

=head2 complete($result)

=head2 data($data)

=head2 fail

=head2 status($numerator, $denominator)

=head2 warning($warning)

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
