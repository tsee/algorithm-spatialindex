use strict;
use warnings;
use Test::More tests => 63;
use Algorithm::SpatialIndex;

my $tlibpath;
BEGIN {
  $tlibpath = -d "t" ? "t/lib" : "lib";
}
use lib $tlibpath;

my @limits = qw(12 -2 15 7);
my $index = Algorithm::SpatialIndex->new(
  strategy => 'QuadTree',
  storage  => 'Memory',
  limit_x_low => $limits[0],
  limit_y_low => $limits[1],
  limit_x_up  => $limits[2],
  limit_y_up  => $limits[3],
  bucket_size => 5,
);

isa_ok($index, 'Algorithm::SpatialIndex');

my $strategy = $index->strategy;
isa_ok($strategy, 'Algorithm::SpatialIndex::Strategy::QuadTree');

is($strategy->no_of_subnodes, 4, 'QuadTree has four subnodes');
is_deeply([$strategy->coord_types], [qw(double double double double)], 'QuadTree has four subnodes');


# this is unit testing:
SCOPE: {
  my ($x, $y) = $strategy->_node_center_coords(2, -3, 5, 4);
  my $eps = 1.e-6;
  cmp_ok($x, '<=', 3.5+$eps);
  cmp_ok($x, '>=', 3.5-$eps);
  cmp_ok($y, '<=', 0.5+$eps);
  cmp_ok($y, '>=', 0.5-$eps);

  # assert that we have a top node whatever comes
  ok(defined($strategy->top_node_id), 'Have a top node id');
  my $top_node = $index->storage->fetch_node($strategy->top_node_id);
  isa_ok($top_node, 'Algorithm::SpatialIndex::Node');
  is($top_node->id, $strategy->top_node_id, 'Top node has top_node_id...');
  my $xy = $top_node->coords;

  cmp_ok($xy->[0], '<=', $limits[0]+$eps);
  cmp_ok($xy->[0], '>=', $limits[0]-$eps);
  cmp_ok($xy->[1], '<=', $limits[1]+$eps);
  cmp_ok($xy->[1], '>=', $limits[1]-$eps);
  cmp_ok($xy->[2], '<=', $limits[2]+$eps);
  cmp_ok($xy->[2], '>=', $limits[2]-$eps);
  cmp_ok($xy->[3], '<=', $limits[3]+$eps);
  cmp_ok($xy->[3], '>=', $limits[3]-$eps);
}


my $scale = 2;
my $item_id = 0;
foreach my $x (map {$_/$scale} $limits[0]*$scale..$limits[2]*$scale) {
  foreach my $y (map {$_/$scale} $limits[1]*$scale..$limits[3]*$scale) {
    $index->insert($item_id++, $x, $y);
  }
}
#diag("Inserted $i nodes");

foreach my $coords ([0, 0],
                    [100, 100],
                    [-12, 14])
{
  ok(!defined($strategy->find_node_for(@$coords)), 'Coords outside index have no node');
}


#my @limits = qw(12 -2 15 7);
foreach my $coords ([12, -2],
                    [12, 7],
                    [15, -2],
                    [15, 7],
                    [14.123, 4.09],
                    [13.123, -1.09],
                    [13, 0])
{
  my $node = $strategy->find_node_for(@$coords);
  # This test is using internal info about the strategy's coordinates
  my $node_coords = $node->coords;
  cmp_ok($node_coords->[Algorithm::SpatialIndex::Strategy::QuadTree::XLOW()],
         '<=', $coords->[0], 'Node lower x boundary okay');
  cmp_ok($node_coords->[Algorithm::SpatialIndex::Strategy::QuadTree::YLOW()],
         '<=', $coords->[1], 'Node lower y boundary okay');
  cmp_ok($node_coords->[Algorithm::SpatialIndex::Strategy::QuadTree::XUP()],
         '>=', $coords->[0], 'Node upper x boundary okay');
  cmp_ok($node_coords->[Algorithm::SpatialIndex::Strategy::QuadTree::YUP()],
         '>=', $coords->[1], 'Node upper y boundary okay');

  ok(defined($index->storage->fetch_bucket($node->id)), 'Node has bucket == leaf');
}


#my @limits = qw(12 -2 15 7);
foreach my $coords ([12, -2, 15, 7],
                    [10, -5, 19, 9],
                    [13, -5, 14, 9],
                    [12.1, 0.1, 13.05, 0.5],
                    )
{
  my @nodes = $strategy->find_nodes_for(@$coords);
  ok(
    ( 0 == grep {!defined($index->storage->fetch_bucket($_->id))} @nodes ),
    'Node has bucket == leaf'
  );
}

#my @limits = qw(12 -2 15 7);
foreach my $coords ([12, -2, 15, 7],
                    [10, -5, 19, 9],
                    )
{
  my @items = $index->get_items_in_rect(@$coords);
  is(scalar(@items), $item_id, 'Encompassing coords get all elems');
}

