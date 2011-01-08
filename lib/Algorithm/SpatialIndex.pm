package Algorithm::SpatialIndex;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.01';

use Module::Pluggable (
  sub_name    => 'strategies',
  search_path => [__PACKAGE__ . "::Strategy"],
  require     => 1,
  inner       => 0,
);

use Module::Pluggable (
  sub_name    => 'storage_backends',
  search_path => [__PACKAGE__ . "::Storage"],
  require     => 1,
  inner       => 0,
);

use Algorithm::SpatialIndex::Node;
use Algorithm::SpatialIndex::Bucket;
use Algorithm::SpatialIndex::Strategy;
use Algorithm::SpatialIndex::Storage;

use Class::XSAccessor {
  getters => [qw(
    strategy
    storage
    limit_x_low
    limit_x_up
    limit_y_low
    limit_y_up
    bucket_size
  )],
};

sub new {
  my $class = shift;
  my %opt = @_;

  my $self = bless {
    limit_x_low => -100,
    limit_x_up  => 100,
    limit_y_low => -100,
    limit_y_up  => 100,
    bucket_size => 100,
    %opt,
  } => $class;

  $self->_init_strategy(\%opt);
  $self->_init_storage(\%opt);
  $self->strategy->_set_storage($self->storage);
  $self->strategy->_super_init_storage();

  return $self;
}

sub _init_strategy {
  my $self = shift;
  my $opt = shift;
  my $strategy = $opt->{strategy};

  croak("Need strategy") if not defined $strategy;
  my @strategies = grep /\Q$strategy\E$/, $self->strategies;
  if (@strategies == 0) {
    croak("Could not find specified strategy '$strategy'. Available strategies: " . join(', ', @strategies));
  }
  elsif (@strategies > 1) {
    croak("Found multiple matching strategy for '$strategy': " . join(', ', @strategies));
  }
  $strategy = shift @strategies;
  $self->{strategy} = $strategy->new(%$opt, index => $self);
}

sub _init_storage {
  my $self = shift;
  my $opt = shift;
  my $storage = $opt->{storage};

  croak("Need storage") if not defined $storage;
  my @storage_backends = grep /\Q$storage\E$/, $self->storage_backends;
  if (@storage_backends == 0) {
    croak("Could not find specified storage backends '$storage'");
  }
  elsif (@storage_backends > 1) {
    croak("Found multiple matching storage backends for '$storage': " . join(', ', @storage_backends));
  }
  $storage = shift @storage_backends;
  $self->{storage} = $storage->new(index => $self, opt => $opt);
}

sub insert {
  my $self = shift;
  return $self->strategy->insert(@_);
}

sub get_items_in_rect {
  my ($self, @rect) = @_;
  my $storage = $self->storage;
  return grep $_->[1] >= $rect[0] && $_->[1] <= $rect[2] &&
              $_->[2] >= $rect[1] && $_->[2] <= $rect[3],
         map {@{$_->items}}
         map $storage->fetch_bucket($_->id),
         $self->strategy->find_nodes_for(@rect);
}

1;
__END__

=head1 NAME

Algorithm::SpatialIndex - Flexible 2D spacial indexing

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    strategy    => 'QuadTree', # or others
    storage     => 'Memory', # or others
    limit_x_low => -100,
    limit_x_up  => 100,
    limit_y_low => -100,
    limit_y_up  => 100,
    bucket_size => 100,
  );
  
  # fill (many times with different values):
  $idx->insert($id, $x, $y);
  
  # query
  my @items = $idx->get_items_in_rect($xlow, $ylow, $xup, $yup);
  # @items now contains 0 or more array refs [$id, $x, $y]

=head1 DESCRIPTION

A generic implementation of spatial (2D) indexes with support for
pluggable algorithms (henceforth: I<strategies>) and storage backends.

Right now, this package ships with a quad tree implementation
(L<Algorithm::SpatialIndex::Strategy::QuadTree>) and an in-memory
storage backend (L<Algorithm::SpatialIndex::Storage::Memory>).

=head2 new

Creates a new spatial index. Requires the following parameters:

=over 2

=item strategy

The strategy to use. This is the part of the strategy class name after a leading
C<Algorithm::SpatialIndex::Strategy::>.

=item storage

The storage backend to use. This is the part of the storage class name after a leading
C<Algorithm::SpatialIndex::Storage::>.

=back

The following parameters are optional:

=over 2

=item limit_x_low limit_x_up limit_y_low limit_y_up

The upper/lower limits of the x/y dimensions of the index. Defaults to
C<[-100, 100]> for both dimensions.

=item bucket_size

The number of items to store in a single leaf node (bucket). If this
number is exceeded by an insertion, the node is split up according
to the chosen strategy.

C<bucket_size> defaults to 100.

=head2 insert

Insert a new item into the index. Takes the unique
item id, an x-, and a y coordinate as arguments.

=head2 get_items_in_rect

Given the coordinates of two points that define a rectangle,
this method finds all items within that rectangle.

Returns a list of array references each of which
contains the id and coordinates of a single item.

=head1 SEE ALSO

L<Algorithm::QuadTree>

L<Tree::M>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
