use inc::Module::Install;
name 'AnyEvent-Gearman';
all_from 'lib/AnyEvent/Gearman.pm';

requires 'AnyEvent'          => '5.12';
requires 'Any::Moose'        => '0.10';
requires 'Object::Event'     => '1.0';
requires 'Object::Container' => '0.03002';
requires 'Data::UUID';

test_requires 'Test::More';
test_requires 'Test::TCP' => '0.08';

use_test_base;

tests('t/*.t');
author_tests('xt');

auto_include;
auto_set_repository;

WriteAll;
