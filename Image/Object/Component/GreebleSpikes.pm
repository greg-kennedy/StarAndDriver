package Image::Object::Component::GreebleSpikes;
use strict;
use warnings;

sub _vect {
  return '<' . join(', ', @_) . '>';
}

sub _pick { $_[int(rand @_)] }
# One to three very long spikes, look nice as antennas or w/e
sub new
{
  my ($class, $scale) = @_;

  my ($w, $h, $d) = @$scale;

  my $script = '';

  for (0 .. int(rand(3))) {
    my $local_w = rand(.2) * $w;
    my $local_d = rand(.2) * $d;
    my $local_h = (rand(3) + .1) * $h;

    my $local_x = (rand(.8) - .4) * $w;
    my $local_z = (rand(.8) - .4) * $d;

    $script .= "prism {\n";
    $script .= "  conic_sweep\n";
    $script .= "  linear_spline\n";
    $script .= "  0, 1, 5\n";
    $script .= "  " . join(',',
      _vect(-$local_w / 2, -$local_d / 2),
      _vect($local_w / 2, -$local_d / 2),
      _vect($local_w / 2, $local_d / 2),
      _vect(-$local_w / 2, $local_d / 2),
      _vect(-$local_w / 2, -$local_d / 2),
    ) . "\n";
    $script .= "  rotate <180, 0, 0>\n";
    $script .= "  translate <$local_x, 1, $local_z>\n";
    $script .= "  scale <1, $local_h, 1>\n";
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
