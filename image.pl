#!/usr/bin/env perl
use v5.010;
use strict;
use warnings;
# automate some error handling
use autodie;

## SYSTEM MODULES
# create temp files safely
use File::Copy;

## LOCAL MODULES
# make local dir accessible for use statements
use FindBin qw( $RealBin );
use lib $RealBin;

# All 3d generator stuff
use Image;

##############################################################################
# CONFIG
use constant {
  POVRAY => '/usr/local/bin/povray37',
  DPI => 72,
  QUALITY => 11,
  ANTIALIAS => 0,

  #OPTIPNG => '/usr/local/bin/optipng',
  OPTIPNG => '',

  DEBUG => 1,
};

my $scene = Image->new(
  povray => POVRAY,
  dpi => DPI,
  quality => QUALITY,
  antialias => ANTIALIAS,
  optipng => OPTIPNG,
  debug => DEBUG,
);

$scene->generate( background => 'Image::Background::Space', object => 'Image::Object::Ship' );

my $png = $scene->render(800, 600);

