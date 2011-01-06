use strict;
use warnings;
use Test::More tests => 15;
use Algorithm::SpatialIndex;

my $tlibpath;
BEGIN {
  $tlibpath = -d "t" ? "t/lib" : "lib";
}
use lib $tlibpath;

my $index = Algorithm::SpatialIndex->new(
  strategy => 'QuadTree',
  storage  => 'Memory',
  limit_x_low => 12,
  limit_x_up  => 15,
  limit_y_low => -2,
  limit_y_up  => 7,
);

isa_ok($index, 'Algorithm::SpatialIndex');

my $strategy = $index->strategy;
isa_ok($strategy, 'Algorithm::SpatialIndex::Strategy::QuadTree');

is($strategy->no_of_subnodes, 4, 'QuadTree has four subnodes');
is_deeply([$strategy->coord_types], [qw(double double)], 'QuadTree has four subnodes');


# this is unit testing:
SCOPE: {
  my ($x, $y) = $strategy->_new_node_coords(2, 5, -3, 4);
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

  cmp_ok($xy->[0], '<=', 13.5+$eps);
  cmp_ok($xy->[0], '>=', 13.5-$eps);
  cmp_ok($xy->[1], '<=', 2.5+$eps);
  cmp_ok($xy->[1], '>=', 2.5-$eps);
}

