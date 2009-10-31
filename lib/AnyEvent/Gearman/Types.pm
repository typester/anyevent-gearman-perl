package AnyEvent::Gearman::Types;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';

subtype 'AnyEvent::Gearman::Client::Connections'
    => as 'ArrayRef[AnyEvent::Gearman::Client::Connection]';

subtype 'AnyEvent::Gearman::Client::StrConnections'
    => as 'ArrayRef[Str]';

coerce 'AnyEvent::Gearman::Client::Connections'
    => from 'AnyEvent::Gearman::Client::StrConnections' => via {
        for my $con (@$_) {
            next if ref($con) and $con->isa('AnyEvent::Gearman::Client::Connection');
            $con = AnyEvent::Gearman::Client::Connection->new( hostspec => $con );
        }
        $_;
    };

subtype 'AnyEvent::Gearman::Worker::Connections'
    => as 'ArrayRef[AnyEvent::Gearman::Worker::Connection]';

subtype 'AnyEvent::Gearman::Worker::StrConnections'
    => as 'ArrayRef[Str]';

coerce 'AnyEvent::Gearman::Worker::Connections'
    => from 'AnyEvent::Gearman::Worker::StrConnections' => via {
        for my $con (@$_) {
            next if ref($con) and $con->isa('AnyEvent::Gearman::Worker::Connection');
            $con = AnyEvent::Gearman::Worker::Connection->new( hostspec => $con );
        }
        $_;
    };

1;

__END__

=head1 NAME

AnyEvent::Gearman::Types - some subtype definitions

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
