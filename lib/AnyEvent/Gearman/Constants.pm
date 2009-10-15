package AnyEvent::Gearman::Constants;
use strict;
use warnings;
use base 'Exporter';

BEGIN {
    my %constants = (
        CAN_DO             => 1,
        CANT_DO            => 2,
        RESET_ABILITIES    => 3,
        PRE_SLEEP          => 4,
        NOOP               => 6,
        SUBMIT_JOB         => 7,
        JOB_CREATED        => 8,
        GRAB_JOB           => 9,
        NO_JOB             => 10,
        JOB_ASSIGN         => 11,
        WORK_STATUS        => 12,
        WORK_COMPLETE      => 13,
        WORK_FAIL          => 14,
        GET_STATUS         => 15,
        ECHO_REQ           => 16,
        ECHO_RES           => 17,
        SUBMIT_JOB_BG      => 18,
        ERROR              => 19,
        STATUS_RES         => 20,
        SUBMIT_JOB_HIGH    => 21,
        SET_CLIENT_ID      => 22,
        CAN_DO_TIMEOUT     => 23,
        ALL_YOURS          => 24,
        WORK_EXCEPTION     => 25,
        OPTION_REQ         => 26,
        OPTION_RES         => 27,
        WORK_DATA          => 28,
        WORK_WARNING       => 29,
        GRAB_JOB_UNIQ      => 30,
        JOB_ASSIGN_UNIQ    => 31,
        SUBMIT_JOB_HIGH_BG => 32,
        SUBMIT_JOB_LOW     => 33,
        SUBMIT_JOB_LOW_BG  => 34,
        SUBMIT_JOB_SCHED   => 35,
        SUBMIT_JOB_EPOCH   => 36,
    );

    require constant;
    import constant \%constants;

    our @EXPORT = keys %constants;
};

1;

__END__

=head1 NAME

AnyEvent::Gearman::Constants - constants for Gearman client/worker

=head1 SYNOPSIS

    use AnyEvent::Gearman::Constants;

=head1 DESCRIPTION

This module exports some constants for Gearman packet types.
This is for internal use only.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

Pedro Melo <melo@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
