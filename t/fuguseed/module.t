#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The lead module App::FuguSeed (QR-PACK-4).
#
# PAUSE grants the distribution name through the package of this
# module, and it indexes the distribution through that package.
# scripts/dist refuses a tree where no module declares the package
# that the dist.module key of .toolingrc names, so the name below is
# the name that a release needs. The test compiles the module as
# well: no other test loads it.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;

use constant MODULE => 'App::FuguSeed';
use constant FILE   => 'App/FuguSeed.pm';

require_ok(MODULE) or BAIL_OUT('the lead module does not compile');

my $path = $INC{ +FILE };
defined $path or BAIL_OUT( 'the lead module names no path in %INC' );

open my $fh, '<', $path or BAIL_OUT("$path: $!");
my $source = do { local $/ = undef; <$fh> };
close $fh or BAIL_OUT("close $path: $!");

# QR-PACK-4: the package name is the name that PAUSE indexes, and it
# is the dist.module key of .toolingrc.
my $module = MODULE;
like( $source, qr/^package[ \t]+\Q$module\E[ \t]*;$/m,
	'the lead module declares the package that PAUSE indexes' );

# QR-PACK-4: the module holds no code, so scripts/pack packs no part
# of it. t/scripts/pack.t proves that the packed file holds the six
# modules of the program and no other package.
unlike( $source, qr/^[ \t]*sub[ \t]/m,
	'the lead module declares no subroutine' );

done_testing();
