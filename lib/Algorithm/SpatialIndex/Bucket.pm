package Algorithm::SpatialIndex::Bucket;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

use Class::XSAccessor {
  constructor => 'new',
  accessors => [qw(
    node_id
    item_ids
  )],
};

1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Bucket - A container for items

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    strategy => 'QuadTree', # or others
  );

=head1 DESCRIPTION

=head1 METHODS

=head2 new

Constructor

=head2 node_id

Read/write accessor for the id of the node that this bucket
corresponds to.

=head2 item_ids

Read/write accessor for the array ref (or undef if not
initialized) of item ids in this bucket.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
