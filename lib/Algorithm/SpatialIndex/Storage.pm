package Algorithm::SpatialIndex::Storage;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

require Algorithm::SpatialIndex::Strategy;
use Scalar::Util 'weaken';

use Class::XSAccessor {
  getters => [qw(
    index
    no_of_subnodes
  )],
};

sub new {
  my $class = shift;
  my %opt = @_;

  my $self = bless {
    %opt,
  } => $class;

  weaken($self->{index});

  my $strategy = $self->index->strategy;
  $self->{no_of_subnodes} = $strategy->no_of_subnodes;

  $self->init() if $self->can('init');

  return $self;
}

sub fetch_node {
  croak("Not implemented in base class");
}

sub store_node {
  croak("Not implemented in base class");
}



1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Storage - Base class for storage backends

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    storage => 'Memory', # or others
  );

=head1 DESCRIPTION

=head1 METHODS

=head2 new

Constructor. Called by the L<Algorithm::SpatialIndex>
constructor. You probably do not need to call or implement this.
Calls your C<init> method if available.

=head2 init

If your subcass implements this, it will be called on the
fresh object in the constructor.

=head2 fetch_node

Fetch a node from storage by node id.

Has to be implemented in a subclass.

=head2 store_node

Store the provided node while possibly assigning
a new ID to it. Returns the (potentially new) node id.

Has to be implemented in a subclass.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
