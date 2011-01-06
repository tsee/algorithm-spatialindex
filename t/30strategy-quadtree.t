use strict;
use warnings;
use Test::More tests => 8;
use Algorithm::SpatialIndex;

my $tlibpath;
BEGIN {
  $tlibpath = -d "t" ? "t/lib" : "lib";
}
use lib $tlibpath;

my $index = Algorithm::SpatialIndex->new(
  strategy => 'QuadTree',
  storage  => 'Memory',
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
}

