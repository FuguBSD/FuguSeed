#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The vocabulary gate (LIST-VOCABULARY). No file that this repository
# owns names one application of the standards. The two banned stems
# are read from spec/list.md, so this file names neither of them.

use v5.36;
use Test::More;
use FindBin qw($RealBin);

my $root = "$RealBin/../..";
chdir $root or BAIL_OUT("chdir $root: $!");

# The stems sit in the spec as inline code: `stem`.
open my $spec, '<', 'spec/list.md' or BAIL_OUT("spec/list.md: $!");
my @stems;
while ( my $line = <$spec> ) {
	push @stems, $1 while $line =~ /banned stem `([a-z]+)`/g;
}
close $spec;
is( scalar @stems, 2, 'spec/list.md names two banned stems' );

# A file that a pack of FuguBSD/Tooling owns says so in its first
# lines, and it is outside the rule.
sub _synced ($path)
{
	open my $fh, '<', $path or return 0;
	my $head = join q{}, map { <$fh> // q{} } 1 .. 6;
	close $fh;
	return $head =~ /pack of FuguBSD\/Tooling owns this file/;
}

my $banned = join '|', map { quotemeta } @stems;
my @hits;
for my $path (`git ls-files --cached --others --exclude-standard`) {
	chomp $path;
	next if $path eq 't/fuguseed/vocabulary.t' || _synced($path);
	open my $fh, '<', $path or next;
	while ( my $line = <$fh> ) {
		# The rule that names the stems is the one exception.
		next if $line =~ /banned stem `/;
		push @hits, "$path:$." if $line =~ /$banned/i;
	}
	close $fh;
}
is( "@hits", q{}, 'no file that this repository owns holds a banned stem' );

done_testing();
