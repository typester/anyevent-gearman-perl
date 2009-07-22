package AnyEvent::Gearman::Client::SharedObject;
use strict;
use warnings;
use Object::Container -Base;

use Data::UUID;

register ug => sub { Data::UUID->new };

1;

