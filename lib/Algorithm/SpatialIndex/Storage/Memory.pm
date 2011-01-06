package Algorithm::SpatialIndex::Storage::Memory;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

use parent 'Algorithm::SpatialIndex::Storage';

use Class::XSAccessor {
  getters => {
    _nodes => 'nodes',
    _options => 'options',
  },
};

sub init {
  my $self = shift;
  $self->{nodes} = [];
  $self->{options} = {};
}

sub fetch_node {
  my $self  = shift;
  my $index = shift;
  my $nodes = $self->_nodes;
  return($index > $#$nodes ? undef : $nodes->[$index]);
}

sub store_node {
  my $self = shift;
  my $node = shift;
  my $nodes = $self->_nodes;
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
  my $self = shift;
  my $key = shift;
  my $value = shift;
  $self->_options->{$key} = $value;
}

1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Storage::Memory - In-memory storage backend

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    storage => 'Memory',
  );

=head1 DESCRIPTION

Inherits from L<Algorithm::SpatialIndex::Storage>.

This storage backend is volatile.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
