use strict;
use warnings;
use lib 'lib';
use Algorithm::SpatialIndex;
use Algorithm::QuadTree;
use Benchmark qw(cmpthese);

my $use_dbi = 0;
if ($use_dbi) {
  eval "use DBI; use DBD::SQLite;";
  unlink 't.sqlite';
  $use_dbi = DBI->connect("dbi:SQLite:dbname=t.sqlite", "", "");
}

my $bucks = 50;
my $scale = 2;
my $depth = 10;
my @limits = qw(-10 -10 10 10);
my @si_opt = (
  strategy => 'QuadTree',
  storage  => 'Memory',
  limit_x_low => $limits[0],
  limit_y_low => $limits[1],
  limit_x_up  => $limits[2],
  limit_y_up  => $limits[3],
  bucket_size => $bucks,
);
my @si_opt_dbi = (
  strategy => 'QuadTree',
  storage  => 'DBI',
  limit_x_low => $limits[0],
  limit_y_low => $limits[1],
  limit_x_up  => $limits[2],
  limit_y_up  => $limits[3],
  bucket_size => $bucks,
  dbh_rw => $use_dbi,
);
my @qt_opt = (
  -xmin  => $limits[0],
  -ymin  => $limits[1],
  -xmax  => $limits[2],
  -ymax  => $limits[3],
  -depth => $depth,
);

#=pod

cmpthese(
  -2,
  {
    ($use_dbi ? (si_insert_dbi => sub {
      my $idx = Algorithm::SpatialIndex->new(@si_opt_dbi);
      my $i = 0;
      foreach my $x (map {$_/$scale} $limits[0]*$scale..$limits[2]*$scale) {
        foreach my $y (map {$_/$scale} $limits[1]*$scale..$limits[3]*$scale) {
          $idx->insert($i++, $x, $y);
        }
      }
    }):()),
    si_insert => sub {
      my $idx = Algorithm::SpatialIndex->new(@si_opt);
      my $i = 0;
      foreach my $x (map {$_/$scale} $limits[0]*$scale..$limits[2]*$scale) {
        foreach my $y (map {$_/$scale} $limits[1]*$scale..$limits[3]*$scale) {
          $idx->insert($i++, $x, $y);
        }
      }
    },
    qt_insert => sub {
      my $qt = Algorithm::QuadTree->new(@qt_opt);
      my $i = 0;
      foreach my $x (map {$_/$scale} $limits[0]*$scale..$limits[2]*$scale) {
        foreach my $y (map {$_/$scale} $limits[1]*$scale..$limits[3]*$scale) {
          $qt->add($i++, $x, $y, $x, $y);
        }
      }
    },
  }
);

#=cut

my $idx = Algorithm::SpatialIndex->new(@si_opt);
my $idx_dbi = Algorithm::SpatialIndex->new(@si_opt_dbi) if $use_dbi;
my $qt = Algorithm::QuadTree->new(@qt_opt);
my @list;
SCOPE: {
  my $i = 0;
  foreach my $x (map {$_/$scale} $limits[0]*$scale..$limits[2]*$scale) {
    foreach my $y (map {$_/$scale} $limits[1]*$scale..$limits[3]*$scale) {
      $idx->insert($i, $x, $y);
      $idx_dbi->insert($i, $x, $y) if defined $idx_dbi;
      $qt->add($i, $x, $y, $x, $y);
      push @list, [$i, $x, $y];
      $i++;
    }
  }
  warn $i;
}

my @rect_small = (-1.5, -1.4, -1.51, -1.41);
my @rect_med   = (-1.5, -1.4, -0.2, -0.1);
my @rect_big   = (-5, -5, 7, 8);
cmpthese(
  -2,
  {
    ($use_dbi ? (si_poll_small_dbi => sub {
      my @o = $idx_dbi->get_items_in_rect(@rect_small);
    }) :()),
    si_poll_small => sub {
      my @o = $idx->get_items_in_rect(@rect_small);
    },
    qt_poll_small => sub {
      my @r = @rect_small;
      my @o = grep {
        $_->[1] >= $r[0] && $_->[1] <= $r[2] &&
        $_->[2] >= $r[1] && $_->[2] <= $r[3]
      }
      map {$list[$_]}
      @{ $qt->getEnclosedObjects(@r) };
    },
    #si_poll_med   => sub {
    #  my @o = $idx->get_items_in_rect(@rect_med);
    #},
    #qt_poll_med => sub {
    #  my @r = @rect_med;
    #  my @o = grep {
    #    $_->[1] >= $r[0] && $_->[1] <= $r[2] &&
    #    $_->[2] >= $r[1] && $_->[2] <= $r[3]
    #  }
    #  map {$list[$_]}
    #  @{ $qt->getEnclosedObjects(@r) };
    #},
    #si_poll_big   => sub {
    #  my @o = $idx->get_items_in_rect(@rect_big);
    #},
    #qt_poll_big => sub {
    #  my @r = @rect_big;
    #  my @o = grep {
    #    $_->[1] >= $r[0] && $_->[1] <= $r[2] &&
    #    $_->[2] >= $r[1] && $_->[2] <= $r[3]
    #  }
    #  map {$list[$_]}
    #  @{ $qt->getEnclosedObjects(@r) };
    #},
    #prim_poll_small => sub {
    #  my @r = @rect_small;
    #  my @o = grep {
    #    $_->[1] >= $r[0] && $_->[1] <= $r[2] &&
    #    $_->[2] >= $r[1] && $_->[2] <= $r[3]
    #  } @list;
    #},
    #prim_poll_med   => sub {
    #  my @r = @rect_med;
    #  my @o = grep {
    #    $_->[1] >= $r[0] && $_->[1] <= $r[2] &&
    #    $_->[2] >= $r[1] && $_->[2] <= $r[3]
    #  } @list;
    #},
    #prim_poll_big   => sub {
    #  my @r = @rect_med;
    #  my @o = grep {
    #    $_->[1] >= $r[0] && $_->[1] <= $r[2] &&
    #    $_->[2] >= $r[1] && $_->[2] <= $r[3]
    #  } @list;
    #},
  }
);
