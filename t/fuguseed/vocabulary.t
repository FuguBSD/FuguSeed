#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The vocabulary gate (OVW-VOCABULARY). No file that this repository
# owns names one application of the standards. The words come from
# spec/overview.md, so this file names none of them.

use v5.36;
use Test::More;
use FindBin    qw($RealBin $RealScript);
use File::Spec ();
use Cwd        qw(realpath);

my $root = realpath("$RealBin/../..");
chdir $root or BAIL_OUT("chdir $root: $!");
my $self = File::Spec->abs2rel( "$RealBin/$RealScript", $root );

# The rule names each word as inline code: the word `w`.
my $spec  = 'spec/overview.md';
my $rules = do {
	open my $fh, '<', $spec or BAIL_OUT("$spec: $!");
	local $/ = undef;
	<$fh>;
};
my @words = $rules =~ /the word\s+`([a-z]+)`/g;
is( scalar @words, 4, "$spec names four words" );

# One expression matches each word and its plural as a whole word,
# in any letter case. A word that ends in y takes the -ies plural too.
my @forms;
for my $word (@words) {
	push @forms, $word, "${word}s";
	push @forms, substr( $word, 0, -1 ) . 'ies' if $word =~ /y\z/;
}
my $alternatives = join '|', map { quotemeta } @forms;
my $banned       = qr/\b(?:$alternatives)\b/i;

# A file that a pack of FuguBSD/Tooling owns says so in its first
# lines, and it is outside the rule.
sub _synced ($path)
{
	open my $fh, '<', $path or return 0;
	my $head = join q{}, map { <$fh> // q{} } 1 .. 6;
	close $fh;
	return $head =~ /pack of FuguBSD\/Tooling owns this file/;
}

my @hits;
for my $path (`git ls-files --cached --others --exclude-standard`) {
	chomp $path;
	next if $path eq $self;
	next if $path =~ m{^docs/research/};
	next if _synced($path);
	open my $fh, '<', $path or next;
	my $text = do { local $/ = undef; <$fh> };
	close $fh;

	# A code block and a code span hold technical names, so they
	# leave the scan. A block keeps its line feeds, so a hit names
	# the right line.
	$text =~ s/^(```.*?^```[^\n]*)/ $1 =~ tr{\n}{}cdr /gmse;
	$text =~ s/`[^`\n]*`/``/g;
	my $number = 0;
	for my $line ( split /\n/, $text ) {
		$number++;

		# The rule that names the words is the one exception.
		next if $line =~ /the word `/;
		push @hits, "$path:$number" if $line =~ $banned;
	}
}
is( "@hits", q{}, 'no file that this repository owns holds a banned word' );

done_testing();
