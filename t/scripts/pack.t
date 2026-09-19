#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The packer and the packed file (QR-PACK, TEST-PACK-1, TEST-PACK-2,
# TEST-PACK-4, TEST-PACK-6, SEC-RELEASE-3, SEC-TRUST-3).
#
# The test packs the tree into a temporary directory. It runs the
# packed file with the core library of one perl alone: with the perl
# of the test, and with /usr/bin/perl, the perl of the shebang. Then
# it holds the text of the packed file to the header of the packer
# and to the sources of the checkout, line for line. The comparison
# of the header reads its text out of the packer, so the test pins
# the shebang to a literal name.
#
# The test sits outside t/fuguseed/, because .toolingrc names
# t/fuguseed alone in dist.testdir: a test of a script of this
# repository ships in no tarball. mk/local.mk names t/scripts/*.t in
# TEST_GLOBS.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use File::Temp       ();
use Module::CoreList ();
use FindBin          qw($RealBin);
use IPC::Open3       qw(open3);
use Symbol           qw(gensym);

# scripts/pack runs scripts/dist with the perl of this test, and that
# script holds use v5.36.
plan skip_all => 'scripts/dist needs perl v5.36 or later' if $] < 5.036;

my $root = "$RealBin/../..";
chdir $root or BAIL_OUT("chdir $root: $!");

use constant PACKER  => 'scripts/pack';
use constant PROGRAM => 'bin/fuguseed-qr';
use constant PACKED  => 'fuguseed-qr';
use constant OUTPUT  => 't/fuguseed/fixtures/qr/vector4.output';
use constant VERSION => '0.0.0';
use constant BASE    => '/usr/bin/perl';

# SHEBANG:
#	Line 1 of the packed file. The kernel runs this interpreter on
#	the air-gapped computer, so this test holds the line to the
#	literal name of the base perl (QR-PACK-1, D-07). The value
#	comes from this test, never from scripts/pack.
use constant SHEBANG => '#!' . BASE;

# BOUND:
#	The bound on the lines of the packed file outside the word
#	list block. One person reads those lines in full
#	(SEC-RELEASE-3).
use constant BOUND => 1200;

# Test vector 4 of the SeedQR specification.
use constant VECTOR =>
    'forum undo fragile fade shy sign arrest garment culture tube off merit';

# The six modules of the packed file, in dependency order, and the
# program body under package main (QR-PACK-1, QR-PACK-2).
use constant PACKAGES => join q{ }, qw(
    App::FuguSeed::List
    App::FuguSeed::Mnemonic
    App::FuguSeed::Codewords
    App::FuguSeed::Matrix
    App::FuguSeed::Text
    App::FuguSeed::QR
    main
);

# DRIVER:
#	The driver of one run of the packed file. No switch of perl
#	removes a directory from @INC, so the driver sets the list
#	before it loads the file (TEST-PACK-1). The first two
#	arguments are the archlib and the privlib of the child perl,
#	and the third is the packed file. @ARGV is empty when the
#	program runs: an argument is a usage error (QR-PROGRAM-2).
use constant DRIVER =>
    'BEGIN { @INC = splice @ARGV, 0, 2; $0 = shift @ARGV }'
    . ' defined do $0 or die $@ || $!;';

# The child gets no PERL5LIB and no PERL5OPT of this environment, so
# no module comes from outside the core library of that child.
delete local @ENV{qw(PERL5LIB PERL5OPT)};

# _slurp($path):
#	The whole file as text.
sub _slurp ($path)
{
	open my $fh, '<', $path or BAIL_OUT("$path: $!");
	local $/ = undef;
	my $text = <$fh>;
	close $fh or BAIL_OUT("close $path: $!");

	return $text;
}

# _pack($out):
#	Pack the tree into the directory $out, and give the path of
#	the packed file.
sub _pack ($out)
{
	my $file  = "$out/" . PACKED;
	my $fault = gensym;
	my $pid   = open3( my $in, my $report, $fault, $^X, PACKER,
		'--version', VERSION, '--out', $out );
	close $in;

	local $/ = undef;
	my $log   = <$report>;
	my $error = <$fault>;
	waitpid $pid, 0;
	my $status = $? >> 8;
	close $report;
	close $fault;

	BAIL_OUT( PACKER . ": $error" ) if $status != 0;
	like( $log, qr/^Packed \Q$file\E$/m, 'the packer names the packed file' );

	return $file;
}

# _core($perl):
#	The archlib and the privlib of one perl: its core library.
sub _core ($perl)
{
	open my $ph, '-|', $perl, '-MConfig', '-e',
	    'print "$Config{archlib}\n$Config{privlib}\n"'
	    or BAIL_OUT("$perl: $!");
	my @directory = <$ph>;
	close $ph or BAIL_OUT("close $perl: status $?");
	chomp @directory;

	return @directory;
}

# _run($perl, $file, $input):
#	Run the packed file $file on $perl, with the core library of
#	that perl alone. The result is the standard output, the
#	standard error, and the exit code.
sub _run ( $perl, $file, $input )
{
	local $SIG{PIPE} = 'IGNORE';
	my $fault = gensym;
	my $pid   = open3( my $in, my $out, $fault, $perl, '-e', DRIVER,
		_core($perl), $file );

	print {$in} $input or BAIL_OUT('the child takes no input');
	close $in;

	local $/ = undef;
	my $output = <$out>;
	my $error  = <$fault>;
	waitpid $pid, 0;
	my $status = $? >> 8;
	close $out;
	close $fault;

	return ( $output // q{}, $error // q{}, $status );
}

my $directory = File::Temp->newdir;
my $packed    = _pack("$directory");
ok( -x $packed, 'the packer writes one executable file' );

# TEST-PACK-1: the packed file gives the SeedQR of test vector 4 on
# the core library of the perl of this test.
my ( $output, $error, $status ) = _run( $^X, $packed, VECTOR . "\n" );
is( $output, _slurp(OUTPUT), 'the packed file gives the fixture output' );
is( $error,  q{},            'the packed file writes nothing to standard error' );
is( $status, 0,              'the packed file exits 0' );

# TEST-PACK-1: the same run on the base perl. The shebang of the
# packed file names that perl, and the air-gapped computer runs it
# (D-07).
SKIP: {
	# The file test takes the name in a variable: a bareword
	# names a filehandle under no feature bareword_filehandles,
	# and perl v5.34 refuses the constant here.
	my $base = BASE;
	skip "no $base", 3 unless -x $base;

	my ( $text, $quiet, $code ) = _run( $base, $packed, VECTOR . "\n" );
	is( $text,  _slurp(OUTPUT), "$base gives the fixture output" );
	is( $quiet, q{},            "$base writes nothing to standard error" );
	is( $code,  0,              "$base exits 0" );
}

# QR-PACK-3: two packs of one tree are byte-equal, and the file holds
# no build path. The two packs write into two directories, so a path
# of the build would break the first assertion as well.
my $second = File::Temp->newdir;
my $again  = _pack("$second");
is( _slurp($packed), _slurp($again), 'two packs of one tree are byte-equal' );
unlike( _slurp($packed), qr/\Q$directory\E|\Q$second\E/,
	'the packed file holds no build path' );

# The structure of the packed file (QR-PACK-1, QR-PACK-2,
# SEC-TRUST-3). The text of the file must equal the header of the
# packer, one frame for each module, and the program body under
# package main. The frames and the body come from the sources that
# t/fuguseed/qr-program.t scans, so the packed file holds no line
# that the scan of those sources did not read. This test holds no
# second copy of that scan.

# _module($package):
#	The path of the module $package under lib.
sub _module ($package)
{
	( my $path = $package ) =~ s{::}{/}g;

	return "$path.pm";
}

# _header():
#	The HEADER constant of the packer, as the packer writes it
#	into the packed file. scripts/pack holds the one copy of that
#	text, so a comparison with it catches no change of the
#	constant. The shebang assertion below reads the packed file.
sub _header ()
{
	my ($header) = _slurp(PACKER) =~ m{
		^use [ ] constant [ ] HEADER [ ] => [ ] <<'HEADER';\n
		(.*?)
		^HEADER$
	}msx;
	BAIL_OUT( PACKER . ' holds no HEADER constant' )
	    if !defined $header;

	return $header;
}

# _frame($module):
#	The frame of one module in the packed file: the BEGIN block
#	that marks the module as loaded, and the source of the module
#	in a block.
sub _frame ($module)
{
	return "BEGIN { \$INC{'$module'} = __FILE__; }\n{\n"
	    . _slurp("lib/$module") . "}\n\n";
}

# _loaded():
#	The path under lib of each module of this repository that the
#	program loads, from the %INC of a child (QR-PROGRAM-6).
sub _loaded ()
{
	open my $ph, '-|', $^X, '-Ilib', '-MApp::FuguSeed::QR', '-e',
	    'print "$_\n" for sort keys %INC'
	    or BAIL_OUT("$^X: $!");
	my @path = <$ph>;
	close $ph or BAIL_OUT("close $^X: status $?");
	chomp @path;

	return grep { m{\AApp/FuguSeed/} } @path;
}

# _loads($text):
#	Each module name that $text loads. A version is no module:
#	"use v5.34" gives the token "v5". The word list of
#	App::FuguSeed::List holds the words "use" and "require", each
#	one alone on its line, so the pattern takes a space or a tab
#	after the verb.
sub _loads ($text)
{
	return $text =~ /^[ \t]*(?:use|require)[ \t]+([\w:]+)/mg;
}

# _foreign($packed, @loads):
#	Each name of @loads that the hash $packed does not hold, that
#	is no version, and that is no module of the core library of
#	perl 5.034 (TEST-PACK-2).
sub _foreign ( $packed, @loads )
{
	return grep {
		     !$packed->{$_}
		  && !/\Av?[0-9]/
		  && !Module::CoreList::is_core( $_, undef, 5.034 )
	} @loads;
}

my @module = map { _module($_) } grep { $_ ne 'main' } split q{ }, PACKAGES;
my $text   = _slurp($packed);

# QR-PACK-2 and SEC-TRUST-3: the packed set is the set that the
# program loads. t/fuguseed/qr-program.t scans the modules of that
# set, so a module outside it rides in the packed file with no scan.
my @loaded = _loaded();
is( join( q{ }, sort @module ),
	join( q{ }, sort @loaded ),
	'the packed set is the set that the program loads' );

# QR-PACK-1 and D-07: the kernel runs line 1 of the packed file, and
# the air-gapped computer runs the perl of its base system. This test
# holds that line to the literal name of that perl, because the
# comparison below reads the header out of the packer.
my ($shebang) = $text =~ /\A([^\n]*)\n/;
is( $shebang, SHEBANG, 'the packed file runs the base perl' );

# scripts/dist writes one "our $VERSION" line under each package of
# the tarball, so the packed file names the version of its release. A
# count over the whole text is position-blind, so each frame proves
# its own stamp first. The comparison below reads the text without
# those lines.
my $release = VERSION;
my $stamp   = qr/^our[ ]\$VERSION[ ]=[ ]'\Q$release\E';\n/m;
my @part    = split /^(?=BEGIN[ ][{][ ]\$INC[{])/m, $text;

is( scalar @part, @module + 1,
	'the packed file holds one frame for each module' );
is( scalar( () = ( $part[0] // q{} ) =~ /$stamp/g ),
	0, 'the header of the packed file names no version' );
for my $i ( 0 .. $#module ) {
	my $count = () = ( $part[ $i + 1 ] // q{} ) =~ /$stamp/g;
	is( $count, 1, "the frame of $module[$i] names the version once" );
}

( my $bare = $text ) =~ s/$stamp//g;
my $body = _slurp(PROGRAM);
$body =~ s/\A\#![^\n]*\n//;

is(
	$bare,
	_header()
	    . join( q{}, map { _frame($_) } @module )
	    . "package main;\n\n"
	    . $body,
	'the packed file is the header, the six module frames, and the body'
);

# SEC-TRUST-3: the packer writes the header, the BEGIN line and the
# two braces of each frame, and the "package main;" line. No scan of
# a source covers those lines. The comparison above holds each one to
# its expected text, and the header must hold comment lines alone.
my @line = grep { !m{\A(?:\#|\z)} } split /\n/, _header();
is( "@line", q{}, 'the header of the packed file holds no code' );

# QR-PACK-1 and QR-PACK-2: the file holds the six modules, in
# dependency order, and the program body last. It holds no other
# package.
my @package = $text =~ /^package[ \t]+([\w:]+)[ \t]*;/mg;
is( "@package", PACKAGES, 'the packed file holds the six modules and the body' );

# The guard of _loads and _foreign (TEST-PACK-2). A pattern that
# matches nothing gives an empty list and a green test, so the sample
# below proves that the pattern reads each verb, and that the filter
# keeps a name from outside the core.
my $sample = "use Digest::SHA;\n\trequire Fugu::File;\n"
    . "use v5.34;\nuse App::FuguSeed::List;\n";
is( join( q{ }, _loads($sample) ),
	'Digest::SHA Fugu::File v5 App::FuguSeed::List',
	'the load pattern reads each use line and each require line' );
is(
	join( q{ }, _foreign( { 'App::FuguSeed::List' => 1 }, _loads($sample) ) ),
	'Fugu::File',
	'the filter keeps a load outside the packed set and the core'
);

# TEST-PACK-2 and SEC-RELEASE-3: each load of the packed file names a
# module of the packed set, or a module of the core library of perl
# 5.034. The file loads Digest::SHA, so the pattern fires on it.
my %packed = map { $_ => 1 } @package;
my @loads  = _loads($text);
my %load   = map { $_ => 1 } @loads;
ok( $load{'Digest::SHA'}, 'the load pattern fires on the packed file' );
is( join( q{ }, _foreign( \%packed, @loads ) ),
	q{},
	'the packed file names no module outside the packed set and the core' );
unlike( $text, qr/(?<![\w:])Fugu::/,
	'the packed file names no Fugu:: module' );

# SEC-RELEASE-3: one person reads the packed file in full. The word
# list of LIST-MODULE-1 is one heredoc block of the file, and the
# DIGEST constant beside it pins that block, so the person reads the
# lines outside the block. The bound holds that count.
my ( $marker, $block ) = $text =~ m{<<'(\w+)';\n(.*?)^\1$}ms;
defined $block or BAIL_OUT('the packed file holds no heredoc block');
my $whole = () = $text =~ /\n/g;
my $words = () = $block =~ /\n/g;
cmp_ok( $whole - $words, '<', BOUND,
	'a person reads fewer than '
	    . BOUND
	    . " lines outside the $marker block" );

done_testing();
