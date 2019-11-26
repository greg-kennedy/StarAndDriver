package Image::Object::Component::Box;
use strict;
use warnings;

sub _pick { $_[int(rand @_)] }

sub _vect {
  return '<' . join(', ', @_) . '>';
}

# Structural component
#  just a box :)
sub new
{
  my ($class, $scale) = @_;

  my ($w, $h, $d) = map { (rand(.8) + .2) * $_ } @$scale;
  #my ($w, $h, $d) = ($scale->[0], $scale->[1], $scale->[2]);

  my $script = "box {\n";
  $script .= "  " . _vect(-$w / 2, 0, -$d / 2) . ' ' . _vect($w / 2, $h, $d / 2) . "\n";
  $script .= '  texture { Tex' . _pick(1 .. 5) . " }\n";
  $script .= "}";

  my $self = {
    script => $script,
    links => [
      # one for each point
      { point => [ 0, $h, 0], rotation => [ 0, 0, 0 ], scale => [$w, $h, $d] },
      { point => [ -$w / 2, $h / 2, 0 ], rotation => [ 0, 0, 90 ], scale => [$h, $w, $d] },
      { point => [ $w / 2, $h / 2, 0 ], rotation => [ 0, 0, -90 ], scale => [$h, $w, $d] },
      { point => [ 0, $h / 2, -$d / 2 ], rotation => [ -90, 0, 0 ], scale => [$w, $d, $h] },
      { point => [ 0, $h / 2, $d / 2 ], rotation => [ 90, 0, 0 ], scale => [$w, $d, $h] },
    ]
  };

  return bless $self, $class;
}

1;
