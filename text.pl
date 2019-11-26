#!/usr/bin/env perl
use v5.010;
use strict;
use warnings;

use Data::Dumper;

## LOCAL MODULES
# make local dir accessible for use statements
use FindBin qw( $RealBin );
use lib $RealBin;

# All text generator stuff
use Text;

print Dumper(Text::generate_text());
