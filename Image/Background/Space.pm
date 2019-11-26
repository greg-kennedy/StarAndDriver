package Image::Background::Space;
use strict;
use warnings;

# helper: choose one item from a list
sub _pick { $_[int(rand @_)] }
sub _chance { rand() < $_[0] }

# generate a random rotation vector
sub _rot { return '<' . (rand(360) - 180) . ', ' . (rand(360) - 180) . ', ' . (rand(360) - 180) . '>' }

# Generate a Space scene.
#  The central volume is clear and objects may float here.
sub generate
{
  my $universe_size = 1024;

  my $sky_angle = _rot();

  # atmospheric layers
  my $atmosphere = '';
  
  while (_chance(2/3))
  {
    my $pattern = 'bozo';
    #my $pattern = 'gradient x';
    #my $pattern = _pick('agate', 'bozo', 'dents', 'granite', 'leopard', 'marble', 'onion', 'quilted', 'ripples', 'spiral1 ' . _pick(1 .. 4), 'spiral2 ' . _pick(1 .. 4), 'waves', 'wood', 'wrinkles');
    $atmosphere .= "texture {\n";
    $atmosphere .= "  pigment { $pattern\n";
    $atmosphere .= "    turbulence " . rand() . "\n";
    $atmosphere .= "    color_map {\n";
    $atmosphere .= "      [0 color rgbt<0, 0, 0, 1>]\n";
    $atmosphere .= "      [1 color srgbt<" . rand() . ", " . rand() . ", " . rand() . ", 0.95>]\n";
    $atmosphere .= "    }\n";
    $atmosphere .= "    scale " . rand($universe_size) . "\n";
    $atmosphere .= "    rotate " . _rot() . "\n";
    $atmosphere .= "  }\n";
    $atmosphere .= "}\n";
  }

  my $script =<<"EOF";
#include "textures.inc"
#include "colors.inc"
camera {
  up y * image_height
  right x * image_width
  location <0, 0, -8>
  look_at <0, 0, 0>
  angle 45
}
light_source { <20, 20, -10>
  color White
}
light_source { <-20, 0, -10>
  color Gray
}
sphere {
  0, 1
  inverse no_shadow no_reflection
  scale $universe_size
  texture { Starfield }
  $atmosphere
  rotate $sky_angle
}
EOF


  # add a planet, 20% chance of it having a ring
  my $ring = _chance(0.2);

  my $r = rand(127) + 128;

  my $pattern = _pick('agate', 'bozo', 'dents', 'granite', 'leopard', 'marble', 'onion', 'quilted', 'ripples', 'spiral1 ' . _pick(1 .. 4), 'spiral2 ' . _pick(1 .. 4), 'waves', 'wood', 'wrinkles');

  if ($ring) { $script .= "union {\n" }
  $script .= "sphere { 0 1\n";
  $script .= "  no_shadow no_reflection";
  $script .= "  pigment{ $pattern\n";
  $script .= "    turbulence " . rand() . "\n";
  $script .= "    color_map {\n";
  $script .= "      [0 color srgb<" . rand() . ", " . rand() . ", " . rand() . ">]\n";
  $script .= "      [1 color srgb<" . rand() . ", " . rand() . ", " . rand() . ">]\n";
  $script .= "    }\n";
  $script .= "    scale " . rand() . "\n";
  $script .= "  }\n";
  $script .= "  finish {\n";
  $script .= "    ambient 0.1\n";
  $script .= "    diffuse 0.6\n";
  $script .= "  }\n";
  if ($ring) { $script .= "}\n";
    $script .= "  union { disc { 0, y, 2, 1.25\n";
    $script .= "                 no_shadow no_reflection\n";
    $script .= "               }\n";
    $script .= "          disc { 0, -y, 2, 1.25\n";
    $script .= "                 no_shadow no_reflection\n";
    $script .= "               }\n";
    $script .= "          pigment { onion scale 2\n";
    $script .= "      color_map {\n";
    my @ring_color = (rand(), rand(), rand());
    $script .= "        [0 color srgbt<0, 0, 0, 1>]\n";
    for (my $i = 62; $i <= 100; $i ++) {
      $script .= "        [" . ($i / 100) . " color srgbf<" . join(',', @ring_color, rand(2/3) + 1/3) . ">]\n";
    }
    $script .= "      }\n";
    $script .= "  }\n";
    $script .= "  finish {\n";
    $script .= "    ambient 0.1\n";
    $script .= "    diffuse 0.6\n";
    $script .= "    }\n";
    $script .= "  }\n";
  }
  $script .= "  rotate " . _rot() . "\n";
  $script .= "  scale " . ($ring ? $r/2 : $r) . "\n";
  $script .= "  translate ($universe_size - $r) * z\n";

  # this line rotates the planet in the viewport, which has a pretty good chance of moving it out of the scene
  $script .= "  rotate <" . rand(90) . ', 0, ' . rand(360) . ">\n";

  $script .= "}\n";

  return $script;
}

1;
