package Image::Object::Component::Tube;
use strict;
use warnings;

use List::Util qw( min );

sub _vect {
  return '<' . join(', ', @_) . '>';
}

sub _pick { $_[int(rand @_)] }
# Structural component
#  it's a tube with a link at both ends
sub new
{
  my ($class, $scale) = @_;

  my ($w, $h, $d) = @$scale;

  # height should be between .5 and 1 of input
  #$h = rand($h/2) + $h/2;

  # radius is smaller of w and h
  my $r = min($w, $d) / 2;

  my $tex = 'Tex' . _pick(1 .. 5);

  my $script = "cylinder {\n";
     $script .= "  0, y * $h, $r\n";
     $script .= "  texture { $tex }\n";
     $script .= "}";

  my $self = {
    script => $script,
    links => [
      # one for each point
      { point => [ 0, $h, 0], rotation => [ 0, rand(360) - 180, 0 ], scale => [$w, $h, $d] },
    ]
  };

  return bless $self, $class;
}

1;
