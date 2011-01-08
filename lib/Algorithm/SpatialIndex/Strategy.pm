package Algorithm::SpatialIndex::Strategy;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

use Algorithm::SpatialIndex::Storage;
use Scalar::Util 'weaken';

use Class::XSAccessor {
  getters => [qw(
    index
    storage
    bucket_size
  )],
};

sub new {
  my $class = shift;
  my %opt = @_;

  my $self = bless {
    %opt,
  } => $class;

  weaken($self->{index});

  $self->init() if $self->can('init');

  return $self;
}

sub _super_init_storage {
  my $self = shift;
  $self->init_storage if $self->can('init_storage');
}

sub _set_storage {
  my $self = shift;
  my $storage = shift;
  $self->{storage} = $storage;
  Scalar::Util::weaken($self->{storage});
}

sub no_of_subnodes { 4 }

sub coord_types { qw(double double double double) }

sub insert {
  croak("insert needs to be implemented in a subclass");
}

sub find_node_for {
  croak("find_node_for needs to be implemented in a subclass");
}

sub find_nodes_for {
  croak("find_nodes_for needs to be implemented in a subclass");
}

1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Strategy - Base class for indexing strategies

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    strategy => 'QuadTree', # or others
  );

=head1 DESCRIPTION

=head1 METHODS

=head2 insert

Inserts a new element into the index. Arguments:
Element (not node!) integer id, Element x/y coordinates.

Needs to be implemented in a subclass.

=head2 find_node_for

Given a pair of x/y coordinates, returns
the L<Algorithm::SpatialIndex::Node>
that contains the given point.

Returns undef if the point is outside of the index range.

Needs to be implemented in a subclass.

=head2 find_nodes_for

Given two pairs of x/y coordinates, returns
all L<Algorithm::SpatialIndex::Node>s that are completely
or partly within the rectangle defined by the two points.

Needs to be implemented in a subclass.

=head2 new

Constructor. Called by the L<Algorithm::SpatialIndex>
constructor. You probably do not need to call or implement this.
Calls your C<init> method if available.

=head2 init

If your subcass implements this, it will be called on the
fresh object in the constructor.

=head2 init_storage

If your subcass implements this, it will be called on the
in the constructor after initializing its storage attribute.

=head2 no_of_subnodes

Returns the number of subnodes per node. Required by the storage
initialization.

The default implementation returns 4 (for a quad tree).
You may want to override that in your subclass.

=head2 coord_types

Returns (as a list) all coordinate types. If you need to store
one x/y pair of floating point coordinates, you may return:

  qw(double double)

or if less precision is acceptable for space savings:

  qw(float float)

If you need to store three coordinates but only in one dimension,
you simply do:

  qw(float float float)

The storage backend is free to upgrade a float to a double
value and even an integer to a double.

Valid coordinate types are:

  float, double, integer, unsigned

The default implementation returns
C<qw(double double double double)> for storing two x/y
coordinate pairs.
You may want to override that in your subclass.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
