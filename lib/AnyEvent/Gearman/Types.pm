package AnyEvent::Gearman::Types;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';

subtype 'ArrayRef[AnyEvent::Gearman::Client::Connection]' => as 'ArrayRef';

coerce 'ArrayRef[AnyEvent::Gearman::Client::Connection]'
    => from 'ArrayRef[Str]' => via {
        for my $con (@$_) {
            next if ref($con) and $con->isa('AnyEvent::Gearman::Client::Connection');
            $con = AnyEvent::Gearman::Client::Connection->new( hostspec => $con );
        }
    };

subtype 'ArrayRef[AnyEvent::Gearman::Worker::Connection]' => as 'ArrayRef';

coerce 'ArrayRef[AnyEvent::Gearman::Worker::Connection]'
    => from 'ArrayRef[Str]' => via {
        for my $con (@$_) {
            next if ref($con) and $con->isa('AnyEvent::Gearman::Worker::Connection');
            $con = AnyEvent::Gearman::Worker::Connection->new( hostspec => $con );
        }
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
