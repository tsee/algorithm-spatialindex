package Algorithm::SpatialIndex::Strategy::QuadTree;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

use parent 'Algorithm::SpatialIndex::Strategy';

# Note that the subnode indexes are as follows:
# (like quadrants in planar geometry)
#
# /---\
# |1|0|
# |-+-|
# |2+3|
# \---/
#

use constant {
  X => 0, # for access to node coords
  Y => 1,
  UPPER_RIGHT_NODE => 0,
  UPPER_LEFT_NODE  => 1,
  LOWER_LEFT_NODE  => 2,
  LOWER_RIGHT_NODE => 3,
};

use Class::XSAccessor {
  getters => [qw(
    top_node_id
    bucket_size
  )],
};

sub init {
  my $self = shift;
}

sub init_storage {
  my $self = shift;
  my $index   = $self->index;
  my $storage = $self->storage;

  # stored bucket_size for persistent indexes
  $self->{bucket_size} = $storage->get_option('bucket_size');
  # or use configured one
  $self->{bucket_size} = $index->bucket_size if not defined $self->bucket_size;

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
  my $nxy = $node->coords;
  my $subnodes = $node->subnode_ids;

  my $storage = $self->storage;

  # If we have a bucket, we are the last level of nodes
  my $bucket = $storage->fetch_bucket($node->id);
  if (defined $bucket) {
    my $item_ids = $bucket->item_ids;
    if (@$item_ids < $self->bucket_size) {
      # sufficient space in bucket. Insert and return
      push @{$item_ids}, $id;
      $storage->store_bucket($bucket);
      return();
    }
    else {
      # bucket full, need to add new layer of nodes and split the bucket
      $self->_split_node($node);
      # refresh data that will have changed:
      $node = $storage->fetch_node($node->id);
      $subnodes = $node->subnode_ids;
      # Now we just continue with the normal subnode checking below:
    }
  }

  my $subnode_index;
  if ($x <= $nxy->[X]) {
    if ($y <= $nxy->[Y]) { $subnode_index = LOWER_LEFT_NODE }
    else                 { $subnode_index = UPPER_LEFT_NODE }
  }
  else {
    if ($y <= $nxy->[Y]) { $subnode_index = LOWER_RIGHT_NODE }
    else                 { $subnode_index = UPPER_RIGHT_NODE }
  }

  if (not defined $subnodes->[$subnode_index]) {
    # FIXME check this node's bucket? Create node?
  }
  else {
    my $subnode = $storage->fetch_node($subnodes->[$subnode_index]);
    croak("Need node '" .$subnodes->[$subnode_index] . '", but it is not in storage!')
      if not defined $subnode;
    return $self->_insert($x, $y, $id, $subnode);
  }
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
