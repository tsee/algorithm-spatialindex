package Algorithm::SpatialIndex::Storage::DBI;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.01';

use parent 'Algorithm::SpatialIndex::Storage';

use constant NODE_ID_TYPE => 'INTEGER UNSIGNED';

use Class::XSAccessor {
  getters => [qw(
    dbh_rw
    table_prefix
    node_coord_sql
    coord_types
    no_of_subnodes
    subnodes_sql
    config
  )],
};

sub dbh_ro {
  my $self = shift;
  if (defined $self->{dbh_ro}) {
    return $self->{dbh_ro};
  }
  return $self->{dbh_rw};
}

sub init {
  my $self = shift;

  my $opt = $self->{opt};
  $self->{dbh_rw} = $opt->{dbh_rw};
  $self->{dbh_ro} = $opt->{dbh_ro};
  $self->{table_prefix} = defined($opt->{table_prefix})
                          ? $opt->{table_prefix} : 'spatialindex_';
  delete $self->{opt};

  my $config_existed = $self->_read_config_table;
  $self->{node_coord_sql} = $self->_coord_types_to_sql($self->coord_types);
  $self->{subnodes_sql}   = $self->_subnodes_sql($self->no_of_subnodes);

  $self->_init_tables();
  
  $self->_write_config() if not $config_existed;
}

sub _read_config_table {
  my $self = shift;
  my $dbh = $self->dbh_ro;
  my $table_prefix = $self->table_prefix;

  my $opt;
  my $success = eval {
    $opt = $dbh->selectall_hashref(
      qq#
        SELECT id, value
        FROM ${table_prefix}_options
      #,
      'id'
    );
    my $err = $dbh->errstr;
    die $err if $err;
    1;
  };
  $opt ||= {};
  $self->{config} = $opt;

  if (defined $opt->{coord_types}) {
    $self->{coord_types} = [split / /, $opt->{coord_types}];
  }
  else {
    $self->{coord_types} = [$self->index->strategy->coord_types];
    $opt->{coord_types} = join ' ', @{$self->{coord_types}};
  }

  $opt->{no_of_subnodes} ||= $self->index->strategy->no_of_subnodes;
  $self->{no_of_subnodes} = $opt->{no_of_subnodes};

  return $success;
}

sub _init_tables {
  my $self = shift;
  my $config_existed = shift;

  my $dbh = $self->dbh_rw;

  my $table_prefix = $self->table_prefix;
  $dbh->do(
    qq#
      CREATE TABLE IF NOT EXISTS ${table_prefix}_options (
        id VARCHAR(255) PRIMARY KEY,
        value VARCHAR(1023)
      )
    #
  );

  my $node_id_type = NODE_ID_TYPE;
  my $coord_sql = $self->node_coord_sql;
  my $subnodes_sql = $self->subnodes_sql;
  $dbh->do(
    qq#
      CREATE TABLE IF NOT EXISTS ${table_prefix}_nodes (
        id $node_id_type PRIMARY KEY,
        $coord_sql,
        $subnodes_sql
      )
    #
  );
}

sub _write_config {
  my $self = shift;
  my $dbh = $self->dbh_rw;

  local $dbh->{AutoCommit} = 0;
  local $dbh->{RaisError} = 1;

  my $table_prefix = $self->table_prefix;
  my $usth = $dbh->prepare(
    qq#
      UPDATE ${table_prefix}_options
      SET id=?, value=?
      WHERE id=?
    #
  );
  my $isth = $dbh->prepare(
    qq#
      INSERT INTO ${table_prefix}_options
      SET id=?, value=?
    #
  );

  my $success = eval {
    foreach my $key (keys %{$self->{config}) {
      $isth->execute($key, $self->{config}{$key}); 1;
      $usth->execute($key, $self->{config}{$key}, $key); 1;
    }
    $dbh->commit();
    1;
  };
  if (not $success) {
    $dbh->rollback();
  }
}

sub fetch_node {
  my $self  = shift;
  my $index = shift;
  my $nodes = $self->{nodes};
  return($index > $#$nodes ? undef : $nodes->[$index]);
}

sub store_node {
  my $self = shift;
  my $node = shift;
  my $nodes = $self->{nodes};
  my $id = $node->id;
  if (not defined $id) {
    $id = $#{$nodes} + 1;
    $node->id($id);
  }
  $nodes->[$id] = $node;
  return $id;
}

sub get_option {
  my $self = shift;
  return $self->_options->{shift()};
}

sub set_option {
  my $self  = shift;
  my $key   = shift;
  my $value = shift;
  $self->_options->{$key} = $value;
}

sub store_bucket {
  my $self   = shift;
  my $bucket = shift;
  $self->{buckets}->[$bucket->node_id] = $bucket;
}

sub fetch_bucket {
  my $self    = shift;
  my $node_id = shift;
  return $self->{buckets}->[$node_id];
}

sub delete_bucket {
  my $self    = shift;
  my $node_id = shift;
  $node_id = $node_id->node_id if ref($node_id);
  my $buckets = $self->{buckets};
  $buckets->[$node_id] = undef;
  pop(@$buckets) while @$buckets and not defined $buckets->[-1];
  return();
}



sub _coord_types_to_sql {
  my $self = shift;
  my $types = shift;
  
  my %types = (
    float    => 'FLOAT',
    double   => 'DOUBLE',
    integer  => 'INTEGER',
    unsigned => 'INTEGER UNSIGNED',
  );
  my $sql = '';
  my $i = 0;
  foreach my $type (@$types) {
    my $sql_type = $types{lc($type)};
    $sql .= "  c$i $sql,\n";
    $i++;
  }
  $sql =~ s/,(.*?)$/$1/;
  return $sql;
}

sub _subnodes_sql {
  my $self = shift;
  my $no_subnodes = shift;
  my $sql = '';
  my $i = 0;
  my $node_id_type = NODE_ID_TYPE;
  foreach my $i (0..$no_subnodes-1) {
    $sql .= "  sn$i $node_id_type,\n";
    $i++;
  }
  $sql =~ s/,(.*?)$/$1/;
}

1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Storage::DBI - DBI storage backend

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $dbh = ...;
  my $idx = Algorithm::SpatialIndex->new(
    storage      => 'DBI',
    dbh_rw       => $dbh,
    dbh_ro       => $dbh, # defaults to dbh_rw
    table_prefix => 'si_',
  );

=head1 DESCRIPTION

Inherits from L<Algorithm::SpatialIndex::Storage>.

This storage backend is persistent.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
