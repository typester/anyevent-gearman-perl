#!perl

use strict;
use warnings;
use Test::More;

use_ok 'AnyEvent::Gearman::Client';
use_ok 'AnyEvent::Gearman::Worker';
use_ok 'AnyEvent::Gearman';

done_testing();