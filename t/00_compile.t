#!perl

use strict;
use warnings;
use Test::More;

use_ok 'AnyEvent::Gearman::Client';
use_ok 'AnyEvent::Gearman::Worker';
use_ok 'AnyEvent::Gearman';

no warnings 'uninitialized', 'once';

diag "Soft dependency versions:";

eval{ require Any::Moose };
diag "    Any::Moose: $Any::Moose::VERSION";

if ($Any::Moose::PREFERRED eq 'Moose') {
    eval { require Moose };
    diag "    Moose: $Moose::VERSION";
}
else {
    eval{ require Mouse };
    diag "    Mouse: $Mouse::VERSION";
}

done_testing();
