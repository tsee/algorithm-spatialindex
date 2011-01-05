package Algorithm::SpatialIndex;
use 5.008001;
use strict;
use warnings;

use Class::XSAccessor {
  getters => [qw(
  )],
};

our $VERSION = '0.01';

sub new {
  my $class = shift;
  my %opt = @_;

  my $self = bless {
    %opt,
  } => $class;

  return $self;
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
