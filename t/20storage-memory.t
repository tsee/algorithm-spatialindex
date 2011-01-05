use strict;
use warnings;
use Test::More tests => 4;
use Algorithm::SpatialIndex;

my $tlibpath;
BEGIN {
  $tlibpath = -d "t" ? "t/lib" : "lib";
}
use lib $tlibpath;

my $index = Algorithm::SpatialIndex->new(
  strategy => 'Test',
  storage  => 'Memory',
);

isa_ok($index, 'Algorithm::SpatialIndex');

my $storage = $index->storage;
isa_ok($storage, 'Algorithm::SpatialIndex::Storage::Memory');

ok(!defined($storage->fetch_node(0)), 'No nodes to start with');
ok(!defined($storage->fetch_node(1)), 'No nodes to start with');

my $node = Algorithm::SpatialIndex::Node->new;

