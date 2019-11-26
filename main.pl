#!/usr/bin/env perl
use v5.010;
use strict;
use warnings;

# automate some error handling
use autodie;

## LOCAL MODULES
# make local dir accessible for use statements
use FindBin qw( $RealBin );
use lib $RealBin;

# Wrapper for PDF functions
use Document;
# All 3d generator stuff
use Image;
# All text generator stuff
use Text;

##############################################################################
# CONFIG
use constant {
  POVRAY => '/usr/local/bin/povray37',
  DPI => 300,
  QUALITY => 11,
  ANTIALIAS => 0,

  OPTIPNG => '/usr/local/bin/optipng',
  #OPTIPNG => '',

  DEBUG => 1,
};

# layout dimensions etc
use constant {
  MARGIN => 18,
  PAGE_W => 612,
  PAGE_H => 792,
};

##############################################################################
# HELPER FUNCTIONS

# helper: choose one item from a list
sub _pick { $_[int(rand @_)] }
# choose item with probability X
#sub chance { rand() < $_[0] }

# helper: create a single-use scene with our defaults
#  and prepopulate it
sub generate_scene
{
  my $scene = Image->new(
    povray => POVRAY,
    dpi => DPI,
    quality => QUALITY,
    antialias => ANTIALIAS,
    optipng => OPTIPNG,
    debug => DEBUG
  );
  $scene->generate(@_);
  return $scene;
}

##############################################################################
# LAYOUT
#  The functions here do layout of a block on the page

# Global definition of all available layouts (const)
use constant LAYOUTS => (
  [
    # full page bleed
    ['2x3'],
  ], [
    # 2x2 square, fill rest with 2x1 or a pair of 1x1
    ['2x2', 0],
    ['2x1', 2],
  ], [
    ['2x2', 0],
    ['1x1', 2, 0],
    ['1x1', 2, 1],
  ], [
    ['2x1', 0],
    ['2x2', 1],
  ], [
    ['1x1', 0, 0],
    ['1x1', 0, 1],
    ['2x2', 1],
  ], [
    # Full-height columnar layouts
    ['1x3', 0],
    ['1x3', 1],
  ], [
    ['1x3', 0],
    ['1x2', 0, 1],
    ['1x1', 2, 1],
  ], [
    ['1x3', 0],
    ['1x1', 0, 1],
    ['1x2', 1, 1],
  ], [
    ['1x3', 0],
    ['1x1', 0, 1],
    ['1x1', 1, 1],
    ['1x1', 2, 1],
  ], [
    ['1x2', 0, 0],
    ['1x1', 2, 0],
    ['1x3', 1],
  ], [
    ['1x1', 0, 0],
    ['1x2', 1, 0],
    ['1x3', 1],
  ], [
    ['1x1', 0, 0],
    ['1x1', 1, 0],
    ['1x1', 2, 0],
    ['1x3', 1],
  ], [
    # 1x2 blocks with 1x1 filler
    ['1x2', 0, 0],
    ['1x1', 2, 0],
    ['1x2', 0, 1],
    ['1x1', 2, 1],
  ], [
    ['1x2', 0, 0],
    ['1x1', 2, 0],
    ['1x1', 0, 1],
    ['1x2', 1, 1],
  ], [
    ['1x1', 0, 0],
    ['1x2', 1, 0],
    ['1x2', 0, 1],
    ['1x1', 2, 1],
  ], [
    ['1x1', 0, 0],
    ['1x2', 1, 0],
    ['1x1', 0, 1],
    ['1x2', 1, 1],
  ], [
    # Single 1x2
    ['1x2', 0, 0],
    ['1x1', 2, 0],
    ['1x1', 0, 1],
    ['1x1', 1, 1],
    ['1x1', 2, 1],
  ], [
    ['1x1', 0, 0],
    ['1x2', 1, 0],
    ['1x1', 0, 1],
    ['1x1', 1, 1],
    ['1x1', 2, 1],
  ], [
    ['1x1', 0, 0],
    ['1x1', 1, 0],
    ['1x1', 2, 0],
    ['1x2', 0, 1],
    ['1x1', 2, 1],
  ], [
    ['1x1', 0, 0],
    ['1x1', 1, 0],
    ['1x1', 2, 0],
    ['1x1', 0, 1],
    ['1x2', 1, 1],
  ], [
    # Mixed wide and tall rectangles
    ['1x2', 0, 0],
    ['1x2', 0, 1],
    ['2x1', 2],
  ], [
    ['2x1', 0],
    ['1x2', 1, 0],
    ['1x2', 1, 1],
  ], [
    # Very broken layouts
    ['1x2', 0, 0],
    ['1x1', 0, 1],
    ['1x1', 1, 1],
    ['2x1', 2],
  ], [
    ['1x1', 0, 0],
    ['1x1', 1, 0],
    ['1x2', 0, 1],
    ['2x1', 2],
  ], [
    ['2x1', 0],
    ['1x2', 1, 0],
    ['1x1', 1, 1],
    ['1x1', 2, 1],
  ], [
    ['2x1', 0],
    ['1x1', 1, 0],
    ['1x1', 2, 0],
    ['1x2', 1, 1],
  ], [
    # Various combinations of 2x1 blocks
    ['2x1', 0],
    ['2x1', 1],
    ['2x1', 2],
  ], [
    ['2x1', 0],
    ['2x1', 1],
    ['1x1', 2, 0],
    ['1x1', 2, 1],
  ], [
    ['2x1', 0],
    ['1x1', 1, 0],
    ['1x1', 1, 1],
    ['2x1', 2],
  ], [
    ['2x1', 0],
    ['1x1', 1, 0],
    ['1x1', 1, 1],
    ['1x1', 2, 0],
    ['1x1', 2, 1],
  ], [
    ['1x1', 0, 0],
    ['1x1', 0, 1],
    ['2x1', 1],
    ['2x1', 2],
  ], [
    ['1x1', 0, 0],
    ['1x1', 0, 1],
    ['2x1', 1],
    ['1x1', 2, 0],
    ['1x1', 2, 1],
  ], [
    ['1x1', 0, 0],
    ['1x1', 0, 1],
    ['1x1', 1, 0],
    ['1x1', 1, 1],
    ['2x1', 2],
  ], [
    ['1x1', 0, 0],
    ['1x1', 0, 1],
    ['1x1', 1, 0],
    ['1x1', 1, 1],
    ['1x1', 2, 0],
    ['1x1', 2, 1],
  ]
);

# Single function for layouts to call
sub layout
{
  # dimensions on page in pt
  my ($doc, $x, $y, $w, $h, $align, $size) = @_;

  my @sizes = (
    [ 10, 9 ],
    [ 12, 10 ],
    [ 16, 14 ]
  );

  # Add some text to the page
  my $text = Text::generate_text();

  # Place text on page.
  my $scene = generate_scene();
  if ($align eq 'top') {
    my $block_height =  $doc->border_text($x, $y, 'top', $w,
      { string => $text->{title}, param => { font => 'helvetica_bold', size => $sizes[$size][0], w => $w } },
      { string => $text->{description}, param => { size => $sizes[$size][1], w => $w } },
      { string => "Location: " . $text->{location} . " | " . $text->{price}, param => { font => 'helvetica_bold', size => $sizes[$size][1], w => $w }}
    );
  
    ###
    # Render a picture of the object.
    my $png = $scene->render($w, $h - $block_height);
    $doc->image($png, $x, $y - $h, $w, $h - $block_height);
  } elsif ($align eq 'left') {
    my $block_width =  $doc->border_text($x, $y, $align, $h,
      { string => $text->{title}, param => { font => 'helvetica_bold', size => $sizes[$size][0], w => $w / 3, h => $h } },
      { string => $text->{description}, param => { size => $sizes[$size][1], w => $w / 3, h => $h } },
      { string => "Location: " . $text->{location} . " | " . $text->{price}, param => { font => 'helvetica_bold', size => $sizes[$size][1], w => $w / 3, h => $h }}
    );
  
    ###
    my $png = $scene->render($w - $block_width, $h);
    $doc->image($png, $x + $block_width, $y - $h, $w - $block_width, $h);
  } else {
    my $block_width =  $doc->border_text($x + (2 * $w / 3), $y, $align, $h,
      { string => $text->{title}, param => { font => 'helvetica_bold', size => $sizes[$size][0], w => $w / 3, h => $h } },
      { string => $text->{description}, param => { size => $sizes[$size][1], w => $w / 3, h => $h } },
      { string => "Location: " . $text->{location} . " | " . $text->{price}, param => { font => 'helvetica_bold', size => $sizes[$size][1], w => $w / 3, h => $h }}
    );
  
    ###
    my $png = $scene->render($w - $block_width, $h);
    $doc->image($png, $x, $y - $h, $w - $block_width, $h);
  }
}

# Full page spread (2x3)
sub layout_2x3
{
  my ($doc) = @_;

  # dimensions on page in pt
  my $x = MARGIN;
  my $y = PAGE_H - MARGIN;
  my $w = PAGE_W - (2 * MARGIN);
  my $h = PAGE_H - (2 * MARGIN);

  layout($doc, $x, $y, $w, $h, 'top', 2);
}

# 2x2 square layout
sub layout_2x2
{
  my ($doc, $row) = @_;

  my $x = MARGIN;
  my $w = PAGE_W - (2 * MARGIN);

  # compute box height, which should be 2/3 of a full page,
  #  less a margin and a half
  my $h = (2 * PAGE_H - (5 * MARGIN)) / 3;
  my $y;
  if ($row == 0) {
    $y = PAGE_H - MARGIN;
  } else {
    $y = $h + MARGIN;
  }

  layout($doc, $x, $y, $w, $h, 'top', 2);
}

# 2x1 wide rectangular layout
sub layout_2x1
{
  my ($doc, $row) = @_;

  my $x = MARGIN;
  my $w = PAGE_W - (2 * MARGIN);

  # compute box height, which should be 1/3 of a full page, less margins
  my $h = (PAGE_H - (4 * MARGIN)) / 3;
  my $y;
  if ($row == 0) {
    $y = PAGE_H - MARGIN;
  } elsif ($row == 1) {
    $y = (PAGE_H + $h) / 2;
  } else {
    $y = $h + MARGIN;
  }

  layout($doc, $x, $y, $w, $h, _pick('left', 'right'), 1);
}

# 1x3 tall whole-column layout
sub layout_1x3
{
  my ($doc, $col) = @_;

  my $y = PAGE_H - MARGIN;
  my $h = PAGE_H - (2 * MARGIN);

  # compute box width, which is 1/2 a full page, minus center + edge margins
  my $w = (PAGE_W / 2) - (1.5 * MARGIN);
  my $x;
  if ($col == 0) {
    $x = MARGIN;
  } else {
    $x = (PAGE_W / 2) + (0.5 * MARGIN);
  }

  layout($doc, $x, $y, $w, $h, 'top', 2);
}

# 1x2 tall column
sub layout_1x2
{
  my ($doc, $row, $col) = @_;

  # compute box width, which is 1/2 a full page, minus center + edge margins
  my $w = (PAGE_W / 2) - (1.5 * MARGIN);
  my $x;
  if ($col == 0) {
    $x = MARGIN;
  } else {
    $x = (PAGE_W / 2) + (0.5 * MARGIN);
  }

  # compute box height, which should be 2/3 of a full page,
  #  less a margin and a half
  my $h = (2 * PAGE_H - (5 * MARGIN)) / 3;
  my $y;
  if ($row == 0) {
    $y = PAGE_H - MARGIN;
  } else {
    $y = $h + MARGIN;
  }

  layout($doc, $x, $y, $w, $h, 'top', 2);
}

# Single block 1x1 layout
sub layout_1x1
{
  my ($doc, $row, $col) = @_;

  # compute box height, which should be 1/3 of a full page, less margins
  my $h = (PAGE_H - (4 * MARGIN)) / 3;
  my $y;
  if ($row == 0) {
    $y = PAGE_H - MARGIN;
  } elsif ($row == 1) {
    $y = (PAGE_H + $h) / 2;
  } else {
    $y = $h + MARGIN;
  }

  # compute box width, which is 1/2 a full page, less margins
  my $w = (PAGE_W / 2) - (1.5 * MARGIN);
  my $x;
  if ($col == 0) {
    $x = MARGIN;
  } else {
    $x = (PAGE_W / 2) + (0.5 * MARGIN);
  }

  layout($doc, $x, $y, $w, $h, _pick('left', 'right', 'top'), 0);
}

##############################################################################
##############################################################################
##############################################################################
# MAIN ENTRY POINT
##############################################################################
##############################################################################
##############################################################################

# Create a blank PDF file
my $doc = new Document('out.pdf');

# FRONT COVER
{
  say "Front Cover...";

  # Add a blank page
  $doc->add_page();

  # Make a big fancy image for the background.
  my $scene = generate_scene( object => 'Image::Object::Ship' );
  my $png = $scene->render(PAGE_W, PAGE_H);
  $doc->image( $png, 0, 0, PAGE_W, PAGE_H);

  # Add some text overlay on the page.
  $doc->text('Starship Trader Monthly', PAGE_W / 2, PAGE_H - (2 * MARGIN), { font => 'helvetica_bold', size => 72, align => 'center', color => 'white' });
  $doc->text('November 3519 Edition', PAGE_W / 2, 600, { font => 'helvetica', size => 16, align => 'center', color => 'white' });
  $doc->text("The galaxy's most trusted source for space vehicles.", 60, 250, { font => 'helvetica_bold', size => 24, align => 'left', color => 'yellow', w => 128 });
  $doc->text('New, Used, Salvage: Find It Here!', PAGE_W - 60, 202, { font => 'helvetica_bold', size => 24, align => 'right', color => 'orange', w => 128 });
}

# Add a blank page (inside cover)
$doc->add_page();

# TITLE PAGE
{
  say "Title Page...";

  $doc->add_page();

  # Add some text to the page
  $doc->text('Starship Trader Monthly', 306, 700, { font => 'helvetica_bold', size => 20, align => 'center' });
  $doc->text('A NaNoGenMo 2019 entry.', 306, 680, { font => 'helvetica', size => 16, align => 'center' });
  $doc->text('Written by the open-source "Star and Driver" software', 306, 660, { font => 'helvetica', size => 16, align => 'center' });
  $doc->text('(https://github.com/greg-kennedy/StarAndDriver),', 306, 640, { font => 'helvetica', size => 16, align => 'center' });
  $doc->text('by Greg Kennedy (kennedy.greg@gmail.com).', 306, 620, { font => 'helvetica', size => 16, align => 'center' });

  $doc->text('Generated on ' . scalar(localtime()) . '.', 306, 100, { font => 'helvetica', size => 16, align => 'center' });
}

# Add a blank page (title back)
$doc->add_page();

# CONTENT PAGES

# Loop N pages
for (my $i = 0; $i < 48; $i ++)
{
  say "page $i...";

  $doc->add_page();

  # Big switch block to fill each layout
  my $pattern = (LAYOUTS)[int(rand(scalar(LAYOUTS)))];

  for (my $j = 0; $j < scalar @$pattern; $j ++) {
    my $block = $pattern->[$j];

    print " . block " . ($j+1) . " of " . scalar(@$pattern) . " (type " . $block->[0] . ")\n";

    if ($block->[0] eq '2x3') {
      layout_2x3($doc);
    } elsif ($block->[0] eq '2x2') {
      layout_2x2($doc, $block->[1]);
    } elsif ($block->[0] eq '2x1') {
      layout_2x1($doc, $block->[1]);
    } elsif ($block->[0] eq '1x3') {
      layout_1x3($doc, $block->[1]);
    } elsif ($block->[0] eq '1x2') {
      layout_1x2($doc, $block->[1], $block->[2]);
    } else {
      layout_1x1($doc, $block->[1], $block->[2]);
    }
  }
}

# Add a blank page (back cover reverse
$doc->add_page();

# BACK COVER
{
  say "Back Cover...";

  $doc->add_page();

  # Back cover is just a starfield
  my $scene = generate_scene( object => 'NONE' );
  my $png = $scene->render(PAGE_W, PAGE_H);
  $doc->image( $png, 0, 0, PAGE_W, PAGE_H);

  # ascii "NANO" + 2019 + check digit
  $doc->barcode( '7865787920193', 456, 54 );
}

# Save the PDF
$doc->close();
