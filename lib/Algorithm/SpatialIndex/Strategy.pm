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

sub no_of_subnodes {
  croak("Not defined in the base class");
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

=head2 new

Constructor. Called by the L<Algorithm::SpatialIndex>
constructor. You probably do not need to call or implement this.
Calls your C<init> method if available.

=head2 init

If your subcass implements this, it will be called on the
fresh object in the constructor.

=head2 no_of_subnodes

Returns the number of subnodes per node. Required by the storage
initialization.

You need to implement this in your subclass.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
