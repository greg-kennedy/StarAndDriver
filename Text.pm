package Text;
use strict;
use warnings;

# automate some error handling
use autodie;

use List::Util qw( shuffle );

sub pick { $_[int(rand @_)] }

######################################
# TEXT GENERATORS

# helper: load a data file and return it
sub load
{
  my @data;
  open (my $fp, '<:encoding(UTF-8)', $_[0]);
  while (my $line = <$fp>) {
    chomp $line;
    push @data, $line;
  }
  close $fp;
  return \@data;
}

#  Load data files
our %data;
$data{ships} = load('data/ships.txt');

$data{makers} = load('data/makers.txt');
$data{industries} = load('data/industries.txt');

$data{materials} = load('data/materials.txt');
$data{energy} = load('data/energy.txt');
$data{tech_buzz} = load('data/tech_buzz.txt');
$data{features} = load('data/features.txt');

$data{planets} = load('data/planets.txt');

$data{names} = load('data/names.txt');

# Item title / name
sub generate_ship {
  return
    uc(pick(@{$data{ships}})) .
    pick('', ' ' . pick('II', 'X', 'DX', 'LE', 'Omega', 'Advanced', 'Special', 'Limited'));
}

sub generate_company {
  return
    pick(@{$data{makers}}) . ' ' .
    pick(@{$data{industries}}) .
    pick('', ' ' . pick('Co', 'Inc', 'Corp', 'Ltd', 'GmbH'));
}

sub generate_location {
  return
    pick('', pick('Alpha', 'Beta', 'Delta', 'Gamma') . ' ') .
    pick(@{$data{planets}}) .
    pick('', ' ' . pick('Prime', 'II', 'III', 'IV', 'Station', 'Outpost', 'Colony', 'Base'));
}

sub generate_alien_name {
  my $name = pick(@{$data{names}});
  my $name_count = int(rand 3);
  for (my $i = 0; $i < $name_count; $i ++) {
    $name .= ' ' . pick(@{$data{names}});
  }
  return $name;
}

# contact info
sub generate_alien {
  if (pick(0, 1)) {
    return generate_alien_name();
  }
  # dealership
  my $name = pick(@{$data{names}});
  return $name . ' ' . pick('Shipyard', 'Sales', 'Dealership', 'Astromotive', 'Starships', 'Rocketry');
}

# weird contact number with letters and digits and ipv6 colons
sub generate_contact {
  return sprintf('+1 %s %s : %s',
    join('', map { pick('0' .. '9', 'A' .. 'F') } (1 .. 4)),
    join('', map { pick('0' .. '9', 'A' .. 'F') } (1 .. 3)),
    join('', map { pick('0' .. '9', 'A' .. 'F') } (1 .. 8))
  );
}

# Item description: one paragraph
sub generate_description {
  my ($mfg, $ship, $year) = @_;

  my $desc = '';
  if (pick(1 .. 10) == 1) {
    $desc .= pick('Looking for', 'Seeking', 'Interested in') . ' something ' . pick('dangerous?', 'fun?', 'exciting?', 'different?', 'unique?') . ' ';
  }

  $desc .=
    pick('For sale', 'Now available', 'Check this out', 'LOOK', "Don't miss this", 'Must go', 'Limited stock available', 'Look no further') . pick('!',':',' -');

  # used / new / etc status
  #  this is used also to generate some plausible backstory
  $desc .= pick(' A ', ' This ', ' One ');
  my @stuff;

  my $quality = pick('new', 'used', 'junk');
  if ($quality eq 'new') {
    $desc .= pick('NEW', 'brand new', 'like new', 'lightly used');

    @stuff = (
      'Financing available.',
      pick('Zero', 'No') . ' credits down.',
      '1.99% Standard Galactic APR.',
      'Stop by for a test-flight!',
      'Rated #1 dealer in the system.',
      'A modern twist on an old classic.',
      "Take a seat in the Captain's Chair!",
      'Fresh out of the stardock.',
      pick("Last year's model.", ($year - int(rand(3) + 2)) . ' model year.'),
    );
  } elsif ($quality eq 'used') {
    $desc .= pick('used', 'good condition', 'great condition');

    @stuff = (
      'Clean title!',
      'Low mileage - only ' . int(rand(90000) + 10000) . ' light-years!',
      'Only ' . int(rand(3) + 2) . ' previous owners.',
      'Flies great!',
      'Must see to appreciate!',
      'Detailed maintenance logs and cargo manifest.',
      'Famously owned by ' . generate_alien_name() . '.',
      pick('No accidents.', 'Negligible body damage.', 'Minor wear-and-tear.', 'Some scratches and dents.'),
      pick("Last year's model.", ($year - int(rand(30) + 2)) . ' model year.'),
      'Passed ' . generate_location() . ' inspection.',
      generate_location() . ' license plates.',
      pick('Never seen combat.', 'Served duty, ' . pick(@{$data{planets}}) . ' wars.'),
    );
  } else {
    $desc .= pick('damaged', 'derelict', '(parts only)', 'scrap');
    @stuff = (
      pick('Scuttled ', 'Damaged ', 'Targeted ') . 'by the ' . pick(@{$data{planets}}) . pick(' pirates', ' mercenaries', ' armada', ' fleet') . '.',
      pick('Damaged', 'Wrecked', 'Totaled') . ' in the ' . pick(@{$data{planets}}) . ' war of ' . ($year - int(rand(30))) . '.',
      'Sold AS-IS.',
      'No refunds.',
      'Engines non-functional.',
      'No life support.',
      'Shields un-tested.',
      'Reactor does NOT power on.',
      'Extensive structural damage.',
      int(rand(40000) + 1000) . ' tonnes scrap equivalent.',
      'Will NOT deliver.',
      'A real fixer-upper!',
      'Great price for the right buyer.'
    );
  }

  $desc .= ' ' . pick( $mfg . ' ' . $ship, $ship . pick(', from ', ', by ', ', ' . pick('manufactured', 'produced') . ' by ') . $mfg) . '. ';

  my @stuff2 = shuffle(@stuff);
  for (0 .. pick(0 .. 1)) {
    $desc .= shift(@stuff2) . ' ';
  }


  # features: put these in an array, shuffle it, and deal some off the top
  my @features = (
    pick( pick(@{$data{materials}}) . ' hull' . pick('', ' (' . pick(@{$data{tech_buzz}}) . ')'),
         pick(@{$data{tech_buzz}}) . ' ' . pick(@{$data{materials}}) . ' hull'),
    pick( pick(@{$data{materials}}) . ' armor' . pick('', ' (' . pick(@{$data{tech_buzz}}) . ')'),
         pick(@{$data{tech_buzz}}) . ' ' . pick(@{$data{materials}}) . ' armor'),
    pick( pick(@{$data{energy}}) . ' engine' . pick('', ' (' . pick(@{$data{tech_buzz}}) . ')'),
         pick(@{$data{tech_buzz}}) . ' ' . pick(@{$data{energy}}) . ' engine'),
    pick( pick(@{$data{energy}}) . ' shields' . pick('', ' (' . pick(@{$data{tech_buzz}}) . ')'),
         pick(@{$data{tech_buzz}}) . ' ' . pick(@{$data{energy}}) . ' force field'),
    pick( pick(@{$data{energy}}) . ' power plant' . pick('', ' (' . pick(@{$data{tech_buzz}}) . ')'),
         pick(@{$data{tech_buzz}}) . ' ' . pick(@{$data{energy}}) . ' generator'),
    pick( pick(@{$data{energy}}) . ' weapon system' . pick('', ' (' . pick(@{$data{tech_buzz}}) . ')'),
         pick(@{$data{tech_buzz}}) . ' ' . pick(@{$data{energy}}) . ' weapon system'),
    'Cargo capacity: ' . int(rand(10000) + 1) . ' cubic meters',
    'Maximum passengers: ' . int(rand(100) + 1),
    sprintf("Top speed Warp %.1f", rand(10) + 1),
  );

  # throw a few canned features into the mix, probably a better way to do this but oh well
  my @f = shuffle @{$data{features}};
  for my $i (0 .. 2) {
    push(@features, shift @f);
  }

  my @shuffled = shuffle(@features);

  # now select some off the top
  $desc .= pick("Features include: ", "Equipped with: ", "Comes with: ", "Standard equipment: ", "Including: ", "Extras: ", "");
  for (0 .. pick(0 .. 3))
  {
    $desc .= ucfirst(shift(@shuffled)) . '. ';
  }

  # contact info
  $desc .= pick('', pick('If interested: ', pick('Want', 'Need', 'Interested in') . pick('', ' more') . pick(' details', ' info', ' information', ' pics', ' pictures') . '? ', 'Questions? ')) .
    pick('Contact ', 'Call ', 'Text ', 'Message ', 'Hypermail ', 'Ansible ', 'FTL-mail ', 'Q-message ', 'Transpond to ', 'Send comms to ') .
    pick(generate_alien() . ' at ' . generate_contact(), generate_contact() . pick(', ask for ' . generate_alien(), ' (' . generate_alien() . ')')) . '.';

  return $desc;
}

sub generate_price
{
  return int(rand(999) + 1) . ('0' x int(rand(3) + 1)) . " Credits" . pick('', pick(' OBO', ' or best offer', ' firm'));
}

###############################################################################
# Generate all text and return as hash
###############################################################################
sub generate_text {
  my $ship = generate_ship();
  my $maker = generate_company();

  my $year = 3519;

  return {
    title => $maker . ' "' . $ship . '"',
    description => generate_description($maker, $ship, $year),
    location => generate_location(),
    price => generate_price()
  }
}

1;
