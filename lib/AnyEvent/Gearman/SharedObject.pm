package AnyEvent::Gearman::SharedObject;
use strict;
use warnings;
use Object::Container -Base;

register UUID => sub {
    shift->ensure_class_loaded('Data::UUID');
    Data::UUID->new;
};

1;
