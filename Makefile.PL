use inc::Module::Install;
name 'AnyEvent-Gearman';
all_from 'lib/AnyEvent/Gearman.pm';

requires 'AnyEvent'          => '5.12';
requires 'Any::Moose'        => '0.13';
requires 'Mouse'             => '0.80';
requires 'MouseX::Foreign';
requires 'Object::Event'     => '1.0';
requires 'Object::Container' => '0.03002';

test_requires 'Test::More' => '0.92';
test_requires 'Test::Exception';
test_requires 'Test::Deep';
test_requires 'Test::Base';
test_requires 'Test::TCP' => '0.08';

use_test_base;

tests('t/*.t');
author_tests('xt');

auto_include;
auto_set_repository;

if (author_context) {
    # gfx++
    # repeat testing
    # see also ExtUtils::MM_Any::test_via_harness()
    my $test_moose = q{$(FULLPERLRUN) -MExtUtils::Command::MM -e}
                    .q{ "do 't/force-moose.pl'; }
                    .q{test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')"}
                    .q{ $(TEST_FILES)} . "\n";

    postamble qq{test_dynamic :: moose\n\n}
            . qq{moose ::\n}
            . qq{\t} . $test_moose;
}

WriteAll;
