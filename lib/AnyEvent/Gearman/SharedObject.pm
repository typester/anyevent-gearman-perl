package AnyEvent::Gearman::SharedObject;
use strict;
use warnings;
use Object::Container -Base;

register UUID => sub {
    shift->ensure_class_loaded('Data::UUID');
    Data::UUID->new;
};

1;

__END__

=head1 NAME

AnyEvent::Gearman::SharedObject - shared object container

=head1 SEE ALSO

L<AnyEvent::Gearman>, L<AnyEvent::Gearman::Client>, L<AnyEvent::Gearman::Worker>.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
