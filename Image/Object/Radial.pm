package Image::Object::Radial;
use strict;
use warnings;

use autodie;

use List::Util qw( min );

# improved loader support
use Module::Metadata;

##############################################################################
# RADIAL SYMMETRY GENERATOR
#  e.g. for a Rocket or Space Station or...
#

# helper: choose one item from a list
sub _pick { $_[int(rand @_)] }

##############################################################################
# Autoload generators for Scenes and Objects
sub _load_generators
{
  my $path = shift;

  opendir( my $dh, $path );
  my @files = sort readdir($dh);
  closedir($dh);
  
  my @modules;
  foreach my $file (@files) {
    if ( $file =~ m/^.+\.pm$/ ) {
      print " . $file ... ";

      my $full_path = $path . '/' . $file;
      eval {
        # Extract info from module
        my $info = Module::Metadata->new_from_file( $full_path );

        # Attempt to actually load the file
        require $full_path;

        # Put the module name into the "loaded modules" path
        push @modules, $info->name();

        print "OK!";

      } or print "FAILED: $@";
      print "\n";
    }
  }

  return @modules;
}

print "Image/Object/Component\n";
my @_components = _load_generators('Image/Object/Component');

##############################################################################
# Recursive "generate objects" sub
#  Spits out a Union between the object itself and all its subobjects
sub recurse
{
  my ($origin, $rotation, $scale, $depth) = @_;

  my $script = "";

  my $min_feature_size = min(@$scale);
  if ($min_feature_size > 0.1) {

    $script .= "union {\n";

    my $component_generator = _pick(@_components);
    print "$depth: Component: " . $component_generator . "\n";
    my $component = $component_generator->new($scale);
  
    my $sub_script = $component->{script} . "\n";
    $sub_script =~ s/^/  /gm;
    $script .= $sub_script;
  
    foreach my $link (@{$component->{links}}) {
      my $sub_script = recurse($link->{point}, $link->{rotation}, $link->{scale}, $depth + 1);
      $sub_script =~ s/^/  /gm;
      $script .= $sub_script . "\n";
    }

    $script .= "  rotate <" . join(',', @{$rotation}) . ">\n";
    $script .= "  translate <" . join(',', @{$origin}) . ">\n";
    $script .= "}";
  }

  return $script;
}

# Make a radial
#  A radial begins with a tube, grows in up / down / sides,
#  then clips a wedge and mirrors it around.
sub generate
{
  my ($h, $r) = (1, .25);

  my $idx = _pick(0 .. 3);
  my $slices = (2, 3, 4, 6)[$idx];
  my $angle = (180, 120, 90, 60)[$idx];

  my $script = "#declare radial_slice =\n";
  $script .= "  union {\n";
  $script .= "    cylinder {\n";
  $script .= "      <0, 0, 0> <0, $h, 0> $r\n";
  $script .= '      texture { Tex' . _pick(1 .. 5) . " }\n";
  $script .= "    }\n";

  # up
  $script .= recurse([0, $h, 0], [0, 0, 0], [$r * 2, $h, $r * 2], 0) . "\n";
  # down
  $script .= recurse([0, 0, 0], [0, 0, 180], [$r * 2, $h, $r * 2], 0) . "\n";
  # out - evenly spaced points along the radius
  $script .= recurse([$r, $h / 4, 0], [0, 0, -90], [$r, $h, $r], 0) . "\n";
  $script .= recurse([$r, $h / 2, 0], [0, 0, -90], [$r, $h, $r], 0) . "\n";
  $script .= recurse([$r, 3 * $h / 4, 0], [0, 0, -90], [$r, $h, $r], 0) . "\n";

  # clip a triangle of ship out
  $script .= "    clipped_by {\n";
  $script .= "      plane { <-sin(radians($angle / 2)), 0, cos(radians($angle / 2))>, 0 }\n";
  $script .= "      plane { <-sin(radians($angle / 2)), 0, -cos(radians($angle / 2))>, 0 }\n";
  $script .= "    }\n";
  $script .= "  }\n";

  # ok now place copies of the slices in a circle
  $script .= "union {\n";
  for (my $i = 0; $i < $slices; $i ++)
  {
    $script .= "  object { radial_slice\n";
    $script .= "    rotate " . ($angle * $i) . " * y\n";
    $script .= "  }\n";
  }

  # turn whole thing on side
  $script .= "  rotate <0, " . rand(180) . ", 0>\n";
  $script .= "  rotate <-45, 0, 0>\n";
  $script .= "  translate <0, -.25, 0>\n";
  $script .= "}";

  return $script;
}

1;
