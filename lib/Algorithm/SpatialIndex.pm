package Algorithm::SpatialIndex;
use 5.008001;
use strict;
use warnings;

use Class::XSAccessor {
  getters => [qw(
    minx maxx miny maxy
    min_levels levels_per_node
    table_prefix dbh
    conf_table leaf_table node_table
  )],
};

our $VERSION = '0.01';

use constant CONF_TABLE => '_config';
use constant LEAF_TABLE => '_leaves';
use constant NODE_TABLE => '_nodes';

sub new {
  my $class = shift;
  my %opt = @_;

  my $self = bless {
    table_prefix => 'spatial_index',
    min_levels => '6',
    levels_per_node => '2',
    minx => -1,
    maxx => 1,
    miny => -1,
    maxy => 1,
    dbh => undef,
    %opt,
  } => $class;

  die if not defined $self->dbh;
  $self->init;

  return $self;
}

sub init {
  my $self = shift;

  self->{conf_table} = $self->table_prefix . CONF_TABLE;
  $self->_load_config;

  my $recsize = length(pack("ddNNNNC"));
  
  my $dbh = $self->dbh;
  my $leaftable = $self->table_prefix . LEAF_TABLE;
  $self->{leaf_table} = $leaftable;
  $dbh->do(qq{
    CREATE TABLE IF NOT EXISTS $leaftable (
      id unsigned int PRIMARY INDEX,
      node_id unsigned int INDEX,
      x double,
      y double,
      value unsigned int
    );
  });

  my $nodetable = $self->table_prefix . NODE_TABLE;
  $self->{node_table} = $nodetable;
  $dbh->do(qq{
    CREATE TABLE IF NOT EXISTS $nodetable (
      id unsigned int PRIMARY INDEX,
      data char(1023)
    );
  });
}

sub _load_config {
  my $self = shift;
  my $dbh = $self->dbh;
  my $tablename = $self->conf_table;
  my $conf = eval { $dbh->selectall_hashref(
    qq{
      SELECT key, value FROM $tablename
    },
    'key'
  ) };
  if (not $conf or defined $dbh->errstr) {
    $dbh->do(qq{
      CREATE TABLE $tablename (
        key VARCHAR(255) PRIMARY KEY,
        value VARCHAR(1023)
      );
    });
    my $sth = $dbh->prepare(qq{
      INSERT INTO $tablename (key, value) VALUES (?, ?)
    });
    foreach my $s (
      ['minx', $self->minx],
      ['miny', $self->miny],
      ['maxx', $self->maxx],
      ['maxy', $self->maxy],
      ['min_levels', $self->min_levels],
      ['table_prefix', $self->table_prefix],
      ['levels_per_node', $self->levels_per_node],
    ) {
      $sth->execute(@$s) or die $dbh->errstr;
    }
  }
  else {
    $self->{$_} = $conf->{$_} for keys %$conf;
  }
}
1;
__END__

=head1 NAME

Algorithm::SpatialIndex - DB-backed 2D spatial indexing

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    table_prefix => 'spatial_index',
  );

=head1 DESCRIPTION

=head1 SEE ALSO

L<Algorithm::QuadTree>

L<Tree::M>

=head1 AUTHOR

Steffen Mueller, E<lt>tsee@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
