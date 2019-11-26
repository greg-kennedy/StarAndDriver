package Document;
use strict;
use warnings;

# interact with PDF files
use PDF::API2;

use POSIX qw(strftime);

##############################################################################
# PDF FUNCTIONS

##############################################################################
# IMAGE FUNCTION
#  Usage: image(filename, x, y, w, h)
#
# Draw .png image at filename onto page at x, y, sized w, h.
sub image
{
  my ($self, $filename, $x, $y, $w, $h) = @_;

  my $image = $self->{pdf}->image_png($filename);

  # Create a gfx object on the page
  my $gfx = $self->{page}->gfx();
  # Place it at the specified coords
  $gfx->image($image, $x, $y, $w, $h);
  # All done.
  $self->{pdf}->finishobjects($image, $gfx);
}

sub barcode
{
  my ($self, $message, $x, $y) = @_;

  my $barcode = $self->{pdf}->xo_ean13( # EAN-13 type

    -code => $message, # message

    -zone => 20,       # size of bars
    -umzn => 25,       # upper "mending zone"
    -lmzn => 15,       # lower "mending zone"
    #-quzn => 0,       # quiet zone
    #-ofwt => 0.5,     # overflow width

    -font => $self->{font}{'helvetica'},
    -fnsz => 12,       # font size

    #-ext  => 1,       # extended character set
    #-extn => '...',   # barcode extension
    #-text => '',      # alternative text
  );

  my $gfx = $self->{page}->gfx();
  $gfx->fillcolor('white');
  $gfx->rectxy($x - 9, $y - 9, $x + $barcode->width() + 9, $y + $barcode->height() + 9);
  $gfx->fill();

  $gfx->formimage($barcode, $x, $y, 1);
                         # x    y   size (scaling)
  $self->{pdf}->finishobjects($barcode, $gfx);
}

##############################################################################
# TEXT FUNCTION
#  Usage: text(string, page, {parameters})

# Write STRING onto PAGE.
# Strings are split on space, then reassembled to fit within param{w},
#  advancing to next line if needed.
sub text
{
  my $self = shift;
  my $string = shift;
  my $x = shift;
  my $y = shift;

  # set parameter hash defaults, then override with supplied values
  my %param = (
    font => 'helvetica',
    size => 12,
    w => 540,
    h => 720,
    color => 'black',
    align => 'left',
    %{+shift}
  );

  my $h = 0;

  # split line into component words
  my @words = split /\s/, $string;

  # set the text color
  # Fill words in the bounding box
  while (@words) # && ($y < $param{h}))
  {
    # advance height
    $h += $param{size} + 1;

    return $h if ($h > $param{h});

    # Make a text box, set font and position
    my $pdf_text = $self->{page}->text();
    $pdf_text->fillcolor($param{color});
    $pdf_text->font($self->{font}{$param{font}}, $param{size});
    $pdf_text->translate($x, $y - $h);

    # Repeatedly put words until the string won't fit any more
    my $line = shift @words;
    while (@words) {
      if ($pdf_text->advancewidth($line . ' ' . $words[0]) < $param{w}) {
        $line = $line . ' ' . shift(@words);
      } else {
        last;
      }
    }

    # Put all text onto page
    if ($param{align} eq 'center') {
      $pdf_text->text_center($line);
    } elsif ($param{align} eq 'right') {
      $pdf_text->text_right($line);
    } else {
      $pdf_text->text($line);
    }
    $self->{pdf}->finishobjects($pdf_text);
  }

  return $h;
}

# Given a block of text objects, calculate the height etc
#  then create a block behind it and lay the text on.
sub border_text
{
  my ($self, $x, $y, $align, $box_wh, @texts) = @_;

  my $line_width = 1;

  my $gfx = $self->{page}->gfx();
  $gfx->linewidth($line_width);
  $gfx->strokecolor('darkgreen');
  $gfx->fillcolor('linen');

  my $w = 0;
  my $h = 0;
  foreach my $text (@texts)
  {
    if ($w < $text->{param}{w}) { $w = $text->{param}{w} }
    # margins
    $text->{param}{w} -= 4;
    # addl height restraints
    if (defined $text->{param}{h}) { $text->{param}{h} -= $h }

    my $text_h = $self->text($text->{string}, $x + 2, $y - $h - 2, $text->{param});

    # grow the surrounding border if width or height changed
    $h += $text_h;
  }

  # now we can draw box!
  my $wh;
  if ($align eq 'top') {
    $gfx->rectxy($x + ($line_width / 2), $y - ($line_width / 2), $x + ($line_width / 2) + ($box_wh - $line_width), $y - ($line_width / 2) - ($h + 8 - $line_width));
    $wh = $h + 8;
  } else {
    $gfx->rectxy($x + ($line_width / 2), $y - ($line_width / 2), $x + ($line_width / 2) + ($w - $line_width), $y - ($line_width / 2) - ($box_wh - $line_width));
    $wh = $w;
  }
  $gfx->fillstroke();
  $self->{pdf}->finishobjects($gfx);

  return $wh;
}

# Add a page and advance
sub add_page
{
  my $self = shift;

  # terminate any existing page
  $self->close_page();
  # Add a blank page
  $self->{page} = $self->{pdf}->page();
  # Set the page size
  $self->{page}->mediabox('Letter');
}

# Close a page
sub close_page
{
  my $self = shift;

  if ($self->{page}) {
    # Done with the page
    $self->{pdf}->finishobjects($self->{page});
    delete $self->{page};
  }
}

# Create a new document
sub new
{
  my ($class, $filename) = @_;

  # create the doc
  my $pdf = PDF::API2->new( -file => $filename );

  my $datestamp = strftime("D:%Y%m%d%H%M%SZ", gmtime());

  # create the infohash
  $pdf->info(
    'Author'       => "Greg Kennedy",
    'CreationDate' => $datestamp,
    'ModDate'      => $datestamp,
    'Creator'      => "https://github.com/greg-kennedy/StarAndDriver",
    'Producer'     => "PDF::API2",
    'Title'        => "Starship Trader Monthly",
    'Subject'      => "A NaNoGenMo 2019 Entry",
    'Keywords'     => "generative text,POV-Ray,space,procedural generation,3D rendering"
  );

  # set up the initial display prefs
  $pdf->preferences( -twocolumnright => 1, -displaytitle => 1, -duplexfliplongedge => 1 );

  # Add some built-in fonts to the PDF
  my %font;
  $font{helvetica} = $pdf->corefont('Helvetica');
  $font{helvetica_bold} = $pdf->corefont('Helvetica-Bold');
  #$font{courier} = $pdf->corefont('Courier');

  return bless {
    pdf => $pdf,
    filename => $filename,
    font => \%font,
  }, $class;
}

sub close
{
  my $self = shift;

  $self->close_page();

  $self->{pdf}->save();
}

1;
