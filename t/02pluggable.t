use strict;
use warnings;
use Test::More tests => 1;
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

