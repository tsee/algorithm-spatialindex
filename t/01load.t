use strict;
use warnings;
use Test::More;

my @modules = (
  'Algorithm::SpatialIndex',
  map { "Algorithm::SpatialIndex::" . $_ }
  qw(
    Node
    Bucket
    Strategy
    Storage
    Storage::Memory
    Storage::DBI
    Strategy::QuadTree
  )
);
plan tests => scalar(@modules);

use_ok($_) for @modules;


