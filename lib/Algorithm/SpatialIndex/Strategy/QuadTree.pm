package Algorithm::SpatialIndex::Strategy::QuadTree;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

use parent 'Algorithm::SpatialIndex::Strategy';

use Class::XSAccessor {
  getters => [qw(
    top_node_id
  )],
};

sub init {
  my $self = shift;
}

sub init_storage {
  my $self = shift;
  my $index   = $self->index;
  my $storage = $self->storage;

  $self->{top_node_id} = $storage->get_option('top_node_id');

  if (not defined $self->top_node_id) {
    # create a new top node
    my $node = Algorithm::SpatialIndex::Node->new(
      coords => [
        $self->_new_node_coords($index->limit_x_low, $index->limit_x_up,
                                $index->limit_y_low, $index->limit_y_up)
      ],
    );
    $self->{top_node_id} = $storage->store_node($node);
  }
}

sub insert {
  my ($self, $x, $y, $id) = @_;
  my $storage = $self->storage;

  my $top_node = $storage->fetch_node($self->top_node_id);
  return $self->_insert($x, $y, $id, $top_node);
}

sub _insert {
  my ($self, $x, $y, $id, $node) = @_;
}

sub _new_node_coords {
  # args: $self, $xlow, $xup, $ylow, $yup
  return( ($_[1]+$_[2])/2, ($_[3]+$_[4])/2 );
}

1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Strategy::QuadTree - Basic QuadTree strategy

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    strategy => 'QuadTree',
  );

=head1 DESCRIPTION

A quad tree implementation.

=head1 METHODS

=head1 SEE ALSO

L<Algorithm::QuadTree>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
