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

use Algorithm::SpatialIndex::Strategy;
use Algorithm::SpatialIndex::Storage;

use Class::XSAccessor {
  getters => [qw(
    strategy
    storage
  )],
};

sub new {
  my $class = shift;
  my %opt = @_;

  my $self = bless {
    %opt,
  } => $class;

  $self->_init_storage(\%opt);
  $self->_init_strategy(\%opt);
  return $self;
}

sub _init_strategy {
  my $self = shift;
  my $opt = shift;
  my $strategy = $opt->{strategy};

  croak("Need strategy") if not defined $strategy;
  my @strategies = grep /\Q$strategy\E$/, $self->strategies;
  if (@strategies == 0) {
    croak("Could not find specified strategies '$strategy'");
  }
  elsif (@strategies > 1) {
    croak("Found multiple matching strategies for '$strategy': " . join(', ', @strategies));
  }
  $strategy = shift @strategies;
  $self->{strategy} = $strategy->new(%$opt, index => $self);
}

sub init_storage {
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

1;
__END__

=head1 NAME

Algorithm::SpatialIndex - Flexible 2D spacial indexing

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    # TODO
  );

=head1 DESCRIPTION

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
