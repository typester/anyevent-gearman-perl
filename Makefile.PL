use inc::Module::Install;
name 'AnyEvent-Gearman-Client';
all_from 'lib/AnyEvent/Gearman/Client.pm';

test_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
