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
  XI   => 1, # item X coord index
  YI   => 2, # item Y coord index
  XLOW => 0, # for access to node coords
  YLOW => 1,
  XUP  => 2,
  YUP  => 3,
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
    # create a new top node and its bucket
    my $node = Algorithm::SpatialIndex::Node->new(
      coords => [
        $index->limit_x_low, $index->limit_y_low,
        $index->limit_x_up, $index->limit_y_up
      ],
      subnode_ids => [],
    );
    $self->{top_node_id} = $storage->store_node($node);
    $self->_make_bucket_for_node($node, $storage);
  }
}

sub insert {
  my ($self, $id, $x, $y) = @_;
  my $storage = $self->storage;

  my $top_node = $storage->fetch_node($self->top_node_id);
  return $self->_insert($id, $x, $y, $top_node);
}

SCOPE: {
  no warnings 'recursion';
  sub _insert {
    my ($self, $id, $x, $y, $node) = @_;
    my $nxy = $node->coords;
    my $subnodes = $node->subnode_ids;

    my $storage = $self->storage;

    # If we have a bucket, we are the last level of nodes
    SCOPE: {
      my $bucket = $storage->fetch_bucket($node->id);
      if (defined $bucket) {
        my $items = $bucket->items;
        if (@$items < $self->bucket_size) {
          # sufficient space in bucket. Insert and return
          push @{$items}, [$id, $x, $y];
          $storage->store_bucket($bucket);
          return();
        }
        else {
          # bucket full, need to add new layer of nodes and split the bucket
          $self->_split_node($node, $bucket);
          # refresh data that will have changed:
          $node = $storage->fetch_node($node->id); # has updated subnode ids
          $subnodes = $node->subnode_ids;
          # Now we just continue with the normal subnode checking below:
        }
      }
    } # end scope

    my $subnode_index;
    if ($x <= ($nxy->[XLOW]+$nxy->[XUP])/2) {
      if ($y <= ($nxy->[YLOW]+$nxy->[YUP])/2) { $subnode_index = LOWER_LEFT_NODE }
      else                                    { $subnode_index = UPPER_LEFT_NODE }
    }
    else {
      if ($y <= ($nxy->[YLOW]+$nxy->[YUP])/2) { $subnode_index = LOWER_RIGHT_NODE }
      else                                    { $subnode_index = UPPER_RIGHT_NODE }
    }

    if (not defined $subnodes->[$subnode_index]) {
      die("Cannot find subnode $subnode_index if node id=".$node->id);
    }
    else {
      my $subnode = $storage->fetch_node($subnodes->[$subnode_index]);
      die("Need node '" .$subnodes->[$subnode_index] . '", but it is not in storage!')
        if not defined $subnode;
      return $self->_insert($id, $x, $y, $subnode);
    }
  }
} # end SCOPE

sub _node_center_coords {
  # args: $self, $xlow, $ylow, $xup, $yup
  return( ($_[1]+$_[3])/2, ($_[2]+$_[4])/2 );
}


# Splits the given node into four new nodes of equal
# size and assigns the items
sub _split_node {
  my $self        = shift;
  my $parent_node = shift;
  my $bucket      = shift; # just for speed, can be taken from parent_node

  my $storage = $self->storage;
  my $parent_node_id = $parent_node->id;
  $bucket = $storage->fetch_bucket($parent_node_id) if not defined $bucket;

  my $coords = $parent_node->coords;
  my ($centerx, $centery) = $self->_node_center_coords(@$coords);
  my @child_nodes;

  # UPPER_RIGHT_NODE => 0
  push @child_nodes, Algorithm::SpatialIndex::Node->new(
    coords      => [$centerx, $centery, $coords->[XUP], $coords->[YUP]],
    subnode_ids => [],
  );
  # UPPER_LEFT_NODE => 1
  push @child_nodes, Algorithm::SpatialIndex::Node->new(
    coords      => [$coords->[XLOW], $centery, $centerx, $coords->[YUP]],
    subnode_ids => [],
  );
  # LOWER_LEFT_NODE => 2
  push @child_nodes, Algorithm::SpatialIndex::Node->new(
    coords      => [$coords->[XLOW], $coords->[YLOW], $centerx, $centery],
    subnode_ids => [],
  );
  # LOWER_RIGHT_NODE => 3
  push @child_nodes, Algorithm::SpatialIndex::Node->new(
    coords      => [$centerx, $coords->[YLOW], $coords->[XUP], $centery],
    subnode_ids => [],
  );

  # save nodes
  my $snode_ids = $parent_node->subnode_ids;
  foreach my $cnode (@child_nodes) {
    push @{$snode_ids}, $storage->store_node($cnode);
  }

  # split bucket
  my $items = $bucket->items;
  my @child_items = ([], [], [], []);
  foreach my $item (@$items) {
    if ($item->[XI] <= $centerx) {
      if ($item->[YI] <= $centery) { push @{$child_items[LOWER_LEFT_NODE]}, $item }
      else                         { push @{$child_items[UPPER_LEFT_NODE]}, $item }
    }
    else {
      if ($item->[YI] <= $centery) { push @{$child_items[LOWER_RIGHT_NODE]}, $item }
      else                         { push @{$child_items[UPPER_RIGHT_NODE]}, $item }
    }
  }
  
  # generate buckets
  foreach my $subnode_idx (0..3) {
    $self->_make_bucket_for_node(
      $child_nodes[$subnode_idx],
      $storage,
      $child_items[$subnode_idx]
    );
  }

  # remove the parent node's bucket
  $storage->delete_bucket($bucket);
}

sub _make_bucket_for_node {
  my $self = shift;
  my $node_id = shift;
  my $storage = shift || $self->storage;
  my $items = shift || [];
  $node_id = $node_id->id if ref $node_id;

  my $b = Algorithm::SpatialIndex::Bucket->new(
    node_id => $node_id,
    items   => $items,
  );
  $storage->store_bucket($b);
}


sub find_node_for {
  my ($self, $x, $y) = @_;
  my $storage = $self->storage;
  my $topnode = $storage->fetch_node($self->top_node_id);
  my $coords = $topnode->coords;

  # boundary check
  if ($x < $coords->[XLOW]
      or $x > $coords->[XUP]
      or $y < $coords->[YLOW]
      or $y > $coords->[YUP]) {
    return undef;
  }

  return $self->_find_node_for($x, $y, $storage, $topnode);
}

# TODO: This is almost trivial to rewrite in non-recursive form
SCOPE: {
  no warnings 'recursion';
  sub _find_node_for {
    my ($self, $x, $y, $storage, $node) = @_;

    my $snode_ids = $node->subnode_ids;
    return $node if not @$snode_ids;

    # find the right sub node
    my ($centerx, $centery) = $self->_node_center_coords(@{$node->coords});
    my $subnode_id;
    if ($x <= $centerx) {
      if ($y <= $centery) { $subnode_id = $snode_ids->[LOWER_LEFT_NODE] }
      else                { $subnode_id = $snode_ids->[UPPER_LEFT_NODE] }
    }
    else {
      if ($y <= $centery) { $subnode_id = $snode_ids->[LOWER_RIGHT_NODE] }
      else                { $subnode_id = $snode_ids->[UPPER_RIGHT_NODE] }
    }

    my $snode = $storage->fetch_node($subnode_id);
    return $self->_find_node_for($x, $y, $storage, $snode);
  }
} # end SCOPE


sub find_nodes_for {
  my ($self, $x1, $y1, $x2, $y2) = @_;

  # normalize coords
  my ($xl, $xu) = $x1 < $x2 ? ($x1, $x2) : ($x2, $x1);
  my ($yl, $yu) = $y1 < $y2 ? ($y1, $y2) : ($y2, $y1);

  my $storage = $self->storage;
  my $topnode = $storage->fetch_node($self->top_node_id);
  my $coords = $topnode->coords;

}

# Returns the leaves for the given node
sub _get_all_leaf_nodes {
  my $self = shift;
  my $node = shift;
  my $storage = $self->storage;

  my @leaves;
  my @nodes = ($node);
  while (@nodes) {
    $node = shift @nodes;
    my $snode_ids = $node->subnode_ids;
    if (@$snode_ids) {
      push @nodes, map $storage->fetch_node($_), @$snode_ids;
    }
    else {
      push @leaves, $node;
    }
  }

  return @leaves;
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
