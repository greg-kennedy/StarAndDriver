package Image;
use strict;
use warnings;

use autodie;

## SYSTEM MODULES
# create temp files safely
use File::Temp;

# improved loader support
use Module::Metadata;

use List::Util qw( max );

##############################################################################
# IMAGE GENERATOR
#  This object can generate a scene (recursively), render it,
#  and pretty-print the script used.
# It dynamically loads generators for backgrounds and objects at run-time from
#  the subdirs in Image/.
#
# An Image contains two parts:
#  * a Scene (the background, incl. any moons, stars, planets, atmosphere, etc)
#    with Camera and Lights
#  * an Object (the foreground - spacechip, starbase, whatever)
##############################################################################

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

print "Image/Background/\n";
my @_backgrounds = _load_generators('Image/Background');
print "Image/Object/\n";
my @_objects = _load_generators('Image/Object');

##############################################################################
# Create a scene from available generators

# helper: choose one item from a list
sub _pick { $_[int(rand @_)] }
sub _chance { rand() < $_[0] }

sub new
{
  my ($class, %params) = @_;

  # create the object
  my $self = {
    povray => $params{povray} || '/usr/local/bin/povray37',
    dpi => $params{dpi} || 72,
    quality => $params{quality} || 9,
    antialias => $params{antialias} || 1,

    optipng => $params{optipng} || '',

    debug => $params{debug} || 0,
  };

  return bless $self, $class;
}

sub _generate_object_textures
{
  # make up the textures we can use on this run
  #  ships are either metal, or painted
  my $script = '';
  if (_chance(0.75)) {
    # painted.  Create some multitextures with a solid base and some detailed overlays.
    my $base_bright = rand(.3) + .5;
    my @base_pig = (rand(.2) + $base_bright, rand(.2) + $base_bright, rand(.2) + $base_bright);
    my $base_pigment = '<' . join(',', @base_pig) . '>';

    my $top_pigment = join(',', rand(), rand(), rand());
    my $spec = rand(.4);
    for my $i (1 .. 5) {
      #my $top_pigment = '<' . join(',', rand(), rand(), rand()) . '>';
      my $pattern = _pick('agate', 'bozo', 'dents', 'granite', 'gradient ' . _pick('x', 'y', 'z'), 'leopard', 'marble', 'onion', 'quilted', 'ripples', 'spiral1 ' . _pick(1 .. 4), 'spiral2 ' . _pick(1 .. 4), 'waves', 'wood', 'wrinkles');
      my $normal = _pick('agate', 'bozo', 'bumps', 'crackle', 'dents', 'facets', 'granite', 'marble', 'wrinkles') . ' ' . rand() . ' scale ' . rand() . ' turbulence ' . rand();

      $script .= "#declare Tex$i = texture { pigment { srgb $base_pigment } } texture {\n";
      $script .= "  pigment { $pattern\n";
      $script .= "    turbulence " . rand() . "\n";
      $script .= "    color_map {\n";
      $script .= "      [0 color rgbt<0, 0, 0, 1>]\n";
      $script .= "      [1 color srgbt<" . $top_pigment . ", 0>]\n";
      $script .= "    }\n";
      $script .= "    scale " . rand(2) . "\n";
      $script .= "    rotate <" . rand() . ", " . rand() . ", " . rand() . ">\n";
      $script .= "  }\n";
      $script .= "  normal { $normal } finish { ambient 0.1 diffuse " . (0.9 - $spec) . " specular $spec }\n}\n";
    }
  } else {
    # is metal, choose a type and pick some finishes from metals.inc
    $script .= "#include \"metals.inc\"\n";

    my $type = _pick('Brass', 'Copper', 'Chrome', 'Silver', 'Gold');
    for my $i (1 .. 5) {
      my $pigment = _pick(1 .. 5);
      my $finish = _pick('A' .. 'E');
      my $normal = _pick('agate', 'bozo', 'bumps', 'crackle', 'dents', 'facets', 'granite', 'marble', 'wrinkles') . ' ' . rand() . ' scale ' . rand() . ' turbulence ' . rand();
      $script .= "#declare Tex$i = texture { pigment { P_$type$pigment } normal { $normal } finish { F_Metal$finish } }\n";
    }
  }

  # any glass object should use this one
  $script .= "#include \"glass.inc\"\n";
  my $glass_pigment = _pick('Col_Glass_Old', 'Col_Glass_Winebottle', 'Col_Glass_Beerbottle', 'Col_Glass_Ruby', 'Col_Glass_Green', 'Col_Glass_Dark_Green', 'Col_Glass_Yellow', 'Col_Glass_Orange', 'Col_Glass_Vicksbottle', 'Col_Glass_Clear', 'Col_Glass_General', 'Col_Glass_Bluish');
  my $glass_finish = _pick('1' .. '9', '10');
  $script .= "#declare TexGlass = texture { pigment { $glass_pigment } finish { F_Glass$glass_finish } }\n";
  return $script;
}

# Generate a scene.  This updates internal data structs.
sub generate
{
  my ($self, %params)= @_;

  # The header files and default info for every POV scene
  my $header = "#version 3.7;\nglobal_settings { assumed_gamma 1.0 }\n";

  my $background_generator = $params{background} || _pick(@_backgrounds);
  if ($self->{debug}) { print "Background: " . $background_generator . "\n" }
  my $background = $background_generator->generate();

  my $object_generator = $params{object} || _pick(@_objects);
  # HACK
  if ($object_generator eq 'Image::Object::Hulk') { $object_generator = _pick('Image::Object::Hulk','Image::Object::Ship') }
  if ($self->{debug}) { print "Object: " . $object_generator . "\n" }
  my $object = '';
  if ($object_generator ne 'NONE') { $object = _generate_object_textures() . "\n" . $object_generator->generate() }

  $self->{script} = $header . $background . $object;
}

##############################################################################
# RENDER FUNCTION
#  Usage: render(script, w, h)
#
# Given the POV-Ray script in $script,
#  call POV-Ray and render a .png image.
sub render
{
  my ($self, $w, $h) = @_;

  my $script = $self->{script};

  #if ($self->{debug}) { print $script };

  # Create a POV-Ray script
  #  POV-Ray will not read from stdin (despite what the manual says)
  #  so use a temp file instead.
  my $pov = File::Temp->new( SUFFIX => '.pov' );
  # Write the supplied script to the file.
  print $pov $script;
  # Close file, no more writing
  close $pov;

  # get an output filename for .png
  my (undef, $png) = File::Temp::tempfile( SUFFIX => '.png', OPEN => 0);

  # RENDER COMMAND
  #  Adjust quality settings here (antialiasing, etc)
  my $infile = $pov->filename;
  my $cmd = join(' ',
    $self->{povray},
    #'-V',  # don't be verbose
    '-GD',  # disable "debug" console output
    '-GR',  # disable "render details" output
    '-GS',  # disable "render statistics" output
    '-RVP',  # skip Radiosity preview (goes faster)

    '+I' . $pov->filename,
    '+O' . $png,

    '+W' . int($w*$self->{dpi}/72),
    '+H' . int($h*$self->{dpi}/72),
    '+Q' . $self->{quality},

    ($self->{antialias} ? '+A' : ''),

    # Unless DEBUG, send STDERR to dev null (it's noisy)
    ($self->{debug} ? '' : ' 2>/dev/null'),
  );

  my $pov_size = `wc -l $infile`;
  $pov_size =~ m/^ *(\d+) .*$/;
  print "    . Render: $infile to $png ($1 lines)\n";
  if ($self->{debug}) { print "Command: $cmd\n" }

  # Call POV-Ray to render.
  my $result = system($cmd);
  if ($result) {
    die "ERROR: POV-Ray returned empty image. Script was:\n$script";
  }

  # if OPTIMIZE, call optipng in-place
  if ($self->{optipng}) {
    my $cmd = join(' ',
      $self->{optipng},
      #'-o7',
      '-strip all',
      #'-zm1-9',
      $png,

      ($self->{debug} ? '' : ' 2>/dev/null'),
    );

    print "    . Optimize $png\n";
    if ($self->{debug}) { print "Command: $cmd\n" }

    $result = system($cmd);
    if ($result) {
      die "ERROR: optipng returned non-zero exit status.";
    }
  }

  # return filename of the png
  return $png;
}

1;
