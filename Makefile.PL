use inc::Module::Install;
name 'AnyEvent-Gearman';
all_from 'lib/AnyEvent/Gearman.pm';

test_requires 'Test::More';
use_test_base;

tests('t/*.t');
author_tests('xt');

auto_include;
WriteAll;
