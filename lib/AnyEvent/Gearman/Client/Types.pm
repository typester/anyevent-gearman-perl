package AnyEvent::Gearman::Client::Types;
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

1;
