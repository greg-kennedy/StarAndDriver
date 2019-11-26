package Image::Object::Component::SolidCap;
use strict;
use warnings;

use List::Util qw( min );

# SolidCap is a singular ending piece.
#  It can be a pyramid or a half-sphere of glass.

sub _vect {
  return '<' . join(', ', @_) . '>';
}

sub _pick { $_[int(rand @_)] }

sub new
{
  my ($class, $scale) = @_;

  my $script;
  if (_pick(0, 1)) {
    my $r = min( @$scale ) / 2;
  
    $script = "sphere {\n";
    $script .= "  0 $r\n";
    $script .= "  clipped_by { plane { -y, 0 } }\n";
    $script .= "  texture { TexGlass }\n";
    $script .= "}";
  } else {
    my ($w, $h, $d) = @$scale;
  
    $script = "prism {\n";
    $script .= "  conic_sweep\n";
    $script .= "  linear_spline\n";
    $script .= "  0, 1, 5\n";
    $script .= "  " . join(',',
      _vect(-$w / 2, -$d / 2),
      _vect($w / 2, -$d / 2),
      _vect($w / 2, $d / 2),
      _vect(-$w / 2, $d / 2),
      _vect(-$w / 2, -$d / 2),
    ) . "\n";
    $script .= "  rotate <180, 0, 0>\n";
    $script .= "  translate <0, 1, 0>\n";
    $script .= "  scale <1, $h, 1>\n";
    $script .= "  texture { Tex" . _pick(1 .. 5) . " }\n";
    $script .= "}\n";
  }
  
  my $self = {
    script => $script,
    links => []
  };

  return bless $self, $class;
}

1;
