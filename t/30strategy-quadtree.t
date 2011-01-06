use strict;
use warnings;
use Test::More tests => 2;
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

