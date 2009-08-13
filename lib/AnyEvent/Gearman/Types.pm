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
