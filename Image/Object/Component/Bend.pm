package Image::Object::Component::Bend;
use strict;
use warnings;

use List::Util qw( min );
use Math::Trig qw( rad2deg :pi );

sub _pick { $_[int(rand @_)] }

sub _vect {
  return '<' . join(', ', @_) . '>';
}

# Structural component
#  Bends an pitch to a new one, with a nice cylinder slice.
sub new
{
  my ($class, $scale) = @_;

  my ($w, $h, $d) = @$scale;

  # calculate size of the base
  my $b = min($w, $d);
  my $r = $b / 2;

  # the goal is a loop with two sides of $r length
  #  get us an pitch between 0 and 90
  my $pitch = rand(pip2);

  # these are used to define the clip plane for the torus
  my $dx = cos($pitch);
  my $dz = sin($pitch);

  # rotation about Y axis to point off in some random direction
  my $yaw = rand(pi2) - pi;

  # create the script
  my $script = "torus {\n";
  $script .= "  " . ($r) . ", " . ($r) . "\n";
  $script .= "  clipped_by { plane { x, 0 } }\n";
  $script .= "  clipped_by { plane { <-$dx, 0, -$dz>, 0 } }\n";

  $script .= '  texture { Tex' . _pick(1 .. 5) . " }\n";

  # flip the clipped torus upright
  $script .= "  rotate <0, 0, -90>\n";
  # center it about 0, 0 (right now it is at 0, $r)
  $script .= "  translate <0, 0, -$r>\n";
  $script .= "  rotate <0, " . rad2deg($yaw) . ", 0>\n";
  $script .= "}";

  # figure the points of links on yaw
  my $new_x = (($r * $dx) - $r) * sin($yaw);
  my $new_y = ($r * $dz);
  my $new_z = (($r * $dx) - $r) * cos($yaw);

  my $self = {
    script => $script,
    links => [
      # one at the destination
      { point => [ $new_x, $new_y, $new_z], rotation => [ -rad2deg($pitch), rad2deg($yaw), 0 ], scale => [$w, $h, $d] },
    ]
  };

  return bless $self, $class;
}

1;
