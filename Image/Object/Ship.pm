package Image::Object::Ship;
use strict;
use warnings;

use autodie;

use List::Util qw( min );

# improved loader support
use Module::Metadata;

##############################################################################
# SHIP GENERATOR
#  Build a ship from Components in the Component/ subfolder.
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

  #if ($depth < 3 && $min_feature_size > 0.01) {
  if ($depth < 7 && $min_feature_size > 0.1) {

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

# Make a starship
#  A starship begins with a long box, grows in all directions,
#  half is clipped off, and then the remnant mirrored.
sub generate
{
  my ($w, $h, $d) = (1, .8, 1);

  my $script = '';

  # create the half object
  $script .= "#declare ship_half =\n";
  $script .= "  union {\n";
  $script .= "    box {\n";
  $script .= "      <0, 0, -" . ($d / 2) . "> <" . ($w / 2) . ", $h, " . ($d / 2) . ">\n";
  $script .= '      texture { Tex' . _pick(1 .. 5) . " }\n";
  $script .= "    }\n";

  # up
  $script .= recurse([0, $h, 0], [0, 0, 0], [$w, $h, $d], 0) . "\n";
  # skip -x object as it'll be culled anyway
  $script .= recurse([$w / 2, $h / 2, 0], [0, 0, -90], [$h, $w, $d], 0) . "\n";
  $script .= recurse([0, $h / 2, -$d / 2], [-90, 0, 0], [$w, $d, $h], 0) . "\n";
  $script .= recurse([0, $h / 2, $d / 2], [90, 0, 0], [$w, $d, $h], 0) . "\n";

  # clip half of ship off
  $script .= "    clipped_by {\n";
  $script .= "      plane {\n";
  $script .= "        -x, 0\n";
  $script .= "      }\n";
  $script .= "    }\n";
  $script .= "  }\n";

  # ok now place both objects
  $script .= "union {\n";
  $script .= "  object { ship_half }\n";
  $script .= "  object { ship_half\n";
  $script .= "    scale <-1, 1, 1>\n";
  $script .= "  }\n";

  # turn whole ship on side
  $script .= "  rotate <0, " . _pick(45, -45) . ", 0>\n";
  $script .= "  rotate <-45, 0, 0>\n";
  # ships always end up too high so translate down a couple
  $script .= "  translate <0, -.5, 0>\n";
  $script .= "}";

  return $script;
}

1;
