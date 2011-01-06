use strict;
use warnings;
use Test::More;

my @modules = (
  'Algorithm::SpatialIndex',
  map { "Algorithm::SpatialIndex::" . $_ }
  qw(
    Node
    Strategy
    Storage
    Storage::Memory
    Strategy::QuadTree
  )
);
plan tests => scalar(@modules);

use_ok($_) for @modules;


