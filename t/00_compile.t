#!perl

use strict;
use warnings;
use Test::More;

use_ok 'AnyEvent::Gearman::Client';
use_ok 'AnyEvent::Gearman::Worker';
use_ok 'AnyEvent::Gearman';

no warnings 'uninitialized';

diag "Soft dependency versions:";

eval { require Moose };
diag "    Moose: $Moose::VERSION";

eval{ require Mouse };
diag "    Mouse: $Mouse::VERSION";

eval{ require Any::Moose };
diag "    Any::Moose: $Any::Moose::VERSION";

done_testing();
