use strict;
use warnings;
use Test::More;
use Algorithm::SpatialIndex;

my $tlibpath;
BEGIN {
  $tlibpath = -d "t" ? "t/lib" : "lib";
}
use lib $tlibpath;

if (not eval {require DBI; require DBD::SQLite; 1;}) {
  plan skip_all => 'These tests require DBI and DBD::SQLite';
}
plan tests => 3;

my $dbfile = '21storage-dbi.test.db';
unlink $dbfile if -f $dbfile;

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");
ok(defined($dbh), 'got dbh');

END {
  unlink $dbfile;
}

my $index = Algorithm::SpatialIndex->new(
  strategy => 'Test',
  storage  => 'DBI',
  dbh_rw => $dbh,
);

isa_ok($index, 'Algorithm::SpatialIndex');

my $storage = $index->storage;
isa_ok($storage, 'Algorithm::SpatialIndex::Storage::DBI');

=pod

ok(!defined($storage->fetch_node(0)), 'No nodes to start with');
ok(!defined($storage->fetch_node(1)), 'No nodes to start with');

my $node = Algorithm::SpatialIndex::Node->new;
my $id = $storage->store_node($node);
ok(defined($id), 'New id assigned');
is($node->id, $id, 'New id inserted');

my $fetched = $storage->fetch_node($id);
is_deeply($fetched, $node, 'Node retrievable');

$storage->set_option('foo', 'bar');
is($storage->get_option('foo'), 'bar', 'get/set option works');
is($storage->get_option('foo2'), undef, 'get/set option works for nonexistent keys');

