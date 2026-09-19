#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The packer and the packed file (QR-PACK, TEST-PACK-1, TEST-PACK-2,
# SEC-RELEASE-3, SEC-TRUST-3).
#
# The test packs the tree into a temporary directory. It runs the
# packed file with the core library of one perl alone: with the perl
# of the test, and with /usr/bin/perl, the perl of the shebang. Then
# it holds the text of the packed file to the header of the packer
# and to the sources of the checkout, line for line.
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
#	text.
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

my @module = map { _module($_) } grep { $_ ne 'main' } split q{ }, PACKAGES;
my $text   = _slurp($packed);

# scripts/dist writes one "our $VERSION" line under each package of
# the tarball, so the packed file names the version of its release.
# The comparison below reads the text without those lines.
my $release = VERSION;
my $stamp   = qr/^our[ ]\$VERSION[ ]=[ ]'\Q$release\E';\n/m;
my $count   = () = $text =~ /$stamp/g;
is( $count, scalar @module, 'each module of the packed file names the version' );

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

# SEC-TRUST-3: the header is the one part of the packed file that no
# scan of a source covers, and it holds comment lines alone.
my @line = grep { !m{\A(?:\#|\z)} } split /\n/, _header();
is( "@line", q{}, 'the header of the packed file holds no code' );

# QR-PACK-1 and QR-PACK-2: the file holds the six modules, in
# dependency order, and the program body last. It holds no other
# package.
my @package = $text =~ /^package[ \t]+([\w:]+)[ \t]*;/mg;
is( "@package", PACKAGES, 'the packed file holds the six modules and the body' );

# TEST-PACK-2 and SEC-RELEASE-3: each load names a module of the
# packed set, or a module of the core library of perl 5.034. A
# version is no module: "use v5.34" gives the token "v5". The word
# list of App::FuguSeed::List holds the words "use" and "require",
# each one alone on its line, so the pattern takes a space or a tab
# after the verb.
my %packed = map { $_ => 1 } @package;
my @loads  = $text =~ /^[ \t]*(?:use|require)[ \t]+([\w:]+)/mg;
my @foreign = grep {
	     !$packed{$_}
	  && !/\Av?[0-9]/
	  && !Module::CoreList::is_core( $_, undef, 5.034 )
} @loads;
is( "@foreign", q{}, 'the packed file names no module outside the packed set' );
unlike( $text, qr/(?<![\w:])Fugu::/,
	'the packed file names no Fugu:: module' );

done_testing();
