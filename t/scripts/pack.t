#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The packer and the packed file (QR-PACK, TEST-PACK-1, TEST-PACK-2,
# SEC-RELEASE-3, SEC-TRUST-3).
#
# The test packs the tree into a temporary directory. It runs the
# packed file with the core library of one perl alone: with the perl
# of the test, and with /usr/bin/perl, the perl of the shebang. Then
# it scans the text of the packed file.
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
use File::Temp ();
use FindBin    qw($RealBin);
use IPC::Open3 qw(open3);
use Symbol     qw(gensym);

# scripts/pack runs scripts/dist with the perl of this test, and that
# script holds use v5.36.
plan skip_all => 'scripts/dist needs perl v5.36 or later' if $] < 5.036;

my $root = "$RealBin/../..";
chdir $root or BAIL_OUT("chdir $root: $!");

use constant PACKER  => 'scripts/pack';
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

# The scan of the packed file (SEC-TRUST-3). The strip and the
# patterns below are the copy of t/fuguseed/qr-program.t, which scans
# the seven sources of the checkout and holds the full table of
# caught samples and clean samples. The packed file is the file that
# crosses to the air-gapped computer, and no checkout stands behind
# it there, so it takes the scan of its own text. The guard below
# proves that this copy fires.

# _code($text):
#	The Perl code of $text, without the comments and the string
#	literals. A single-quoted heredoc goes first: the word list
#	of App::FuguSeed::List holds words such as "open" and "fork",
#	and the module holds the list in such a heredoc. A "#" after
#	a "$" is the last index of an array, and not a comment.
#
#	The strip knows three quote-like operators: q, qq and qw,
#	with braces or with parentheses. It knows a match after =~,
#	!~ or split. An apostrophe in another form, such as s///,
#	pairs with a later apostrophe, and the pair deletes the code
#	between the two. The function dies on a form that it cannot
#	parse, because such a form can hide code from the scan
#	below.
#
#	The first branch of the strip keeps the marker of a heredoc,
#	and each guard below reads the stripped code. A marker in a
#	comment or in a string goes away with the comment or the
#	string, and it stops no scan.
sub _code ($text)
{
	$text =~ s/<<'(\w+)';.*?^\1$//msg;

	$text =~ s{
		  ( << ~? (?: ' \w+ ' | " \w+ " ) )
		| ' [^'\\]* (?: \\. [^'\\]* )* '
		| " [^"\\]* (?: \\. [^"\\]* )* "
		| (?<! [\$\@\%&>] ) \b q [qw]? \s* \{ [^{}]* \}
		| (?<! [\$\@\%&>] ) \b q [qw]? \s* \( [^()]* \)
		| (?: =~ | !~ | \b split ) \K \s* m? / [^/\n]* / \w*
		| (?<! \$ ) \# [^\n]*
	}{ $1 // q{} }gex;

	die "_code: the text holds another heredoc\n"
	    if $text =~ / << ~? ['"A-Za-z_] /x;

	my $form = _unknown($text);
	die "_code: the text holds $form\n" if defined $form;

	return $text;
}

# _unknown($code):
#	The name of the first form of the stripped $code that _code
#	cannot parse, or undef. Each quote character of a known form
#	leaves with that form, so a quote character that stays names
#	a form that the strip missed.
sub _unknown ($code)
{
	return 'a quote character' if $code =~ /['"]/;
	return 'a quote-like operator'
	    if $code =~ m{
		    (?<! [\$\@\%&>-] )
		    \b (?: qq | qr | qx | qw | q | m | s | tr | y )
		    \s* [(\{\[<|!\#'"/]
	    }x;

	# The slash of a division and the slash of the defined-or
	# operator follow a term, between two spaces. Each other
	# slash can open a match.
	( my $rest = $code ) =~ s{ (?<= [\w\)\]\}] ) [ ] //? [ ] }{}gx;
	return 'a slash' if $rest =~ m{/};

	return;
}

# $contact:
#	Each builtin of the file system, of process control, of the
#	user information and the group information, of the network,
#	and of System V IPC. The list holds syscall as well, because
#	syscall calls any system call. It holds eof, because eof()
#	and eof(ARGV) open the next file of @ARGV. It holds flock,
#	fcntl and ioctl, because each one reaches past the bytes of
#	a handle. The program must contact nothing but its three
#	standard streams, so SEC-TRUST-3 forbids each one. A sigil
#	before the name makes it a variable, and a fat comma after it
#	makes it a key. Neither one is a call.
my $contact = qr{
	(?<! [\$\@\%] )
	\b(?: open | sysopen | opendir | readdir | closedir | rewinddir
	    | seekdir | telldir | glob | dbmopen | unlink | rename | link
	    | symlink | readlink | mkdir | rmdir | chdir | chroot | chmod
	    | chown | utime | truncate | umask | stat | lstat | eof
	    | flock | fcntl | ioctl
	    | system | exec | fork | qx | readpipe | pipe | wait | waitpid
	    | kill | syscall
	    | socket | socketpair | bind | connect | listen | accept
	    | shutdown | recv | send | getsockname | getpeername
	    | gethostbyname | gethostbyaddr | getservbyname
	    | getpwnam | getpwuid | getpwent | getgrnam | getgrgid
	    | getgrent | getlogin
	    | msgget | msgsnd | msgrcv | semget | semop
	    | shmget | shmread | shmwrite )\b
	(?! \s* => )
}x;

# $file_test:
#	A file test operator, such as -e or -r. Each one reads the
#	file system, and -t reads the state of a filehandle
#	(SEC-TRUST-3).
my $file_test = qr{ (?<! [\w\$] ) - [rwxoRWXOezsfdlpSbctugkTBAMC] \b }x;

# $environment:
#	A read of the environment: %ENV, $ENV{...}, @ENV{...}, and
#	the getenv function of POSIX (SEC-TRUST-3).
my $environment = qr{ \b(?: ENV | getenv )\b }x;

# $read:
#	A read of another handle than standard input: the diamond
#	operator in each of its forms, and readline with another
#	handle. The diamond operator opens each file that @ARGV
#	names, and bin/fuguseed-qr passes @ARGV to run (SEC-TRUST-3).
my $read = qr{
	<> | < (?! STDIN > ) \$? \w+ >
	| \b readline \b (?! \s* \(? \s* \*? STDIN \b )
}x;

# $dynamic:
#	A load of a file, such as require $path or require './x.pl'.
#	The strip above deletes the path of a literal load, so the
#	pattern takes each do and each require that is not a block,
#	a version, or a bareword module (SEC-TRUST-3).
my $dynamic = qr{
	(?<! [\$\@\%>] ) \b(?: do | require )\b
	(?! \s* \{ )
	(?! \s+ v? [0-9] )
	(?! \s+ [A-Za-z_] [\w:]* \s* ; )
}x;

# _hits($code):
#	The name of each contact of the stripped $code with the
#	computer, or an empty list (SEC-TRUST-3). The scan of the
#	sources and the self-test below call this one function, so
#	each pattern above has one place only.
sub _hits ($code)
{
	my @hits = $code =~ /($contact)/g;
	push @hits, 'backtick'  if $code =~ /[`]/;
	push @hits, 'ENV'       if $code =~ $environment;
	push @hits, 'file test' if $code =~ $file_test;
	push @hits, 'read'      if $code =~ $read;
	push @hits, 'load'      if $code =~ $dynamic;

	return @hits;
}

# The guard of the scan. A pattern that matches nothing would take
# each source, and the assertions below would pass on an empty scan.
# One row proves each pattern of _hits.
my @caught = (
	[ q{open my $fh, '<', $path;}, 'open' ],
	[ q{system 'ls';},             'system' ],
	[ q{my $out = `ls`;},          'backtick' ],
	[ q{my $home = $ENV{HOME};},   'ENV' ],
	[ q{my $there = -e $path;},    'file test' ],
	[ q{my $line = <$fh>;},        'read' ],
	[ q{require $path;},           'load' ],
);

my @clean = (
	q{my $line = <STDIN>;},
	q{require Digest::SHA;},
	q{use v5.34;},
);

for my $case (@caught) {
	my ( $sample, $reason ) = @{$case};
	like( join( q{ }, _hits( _code($sample) ) ),
		qr/\Q$reason\E/, "the scan catches $sample" );
}

for my $sample (@clean) {
	is( join( q{ }, _hits( _code($sample) ) ),
		q{}, "the scan takes $sample" );
}

my $code = _code( _slurp($packed) );

# SEC-TRUST-3: the three standard streams are the one contact of the
# packed file with the computer.
is( join( q{ }, _hits($code) ),
	q{}, 'the packed file contacts nothing but its three streams' );

# QR-PACK-1 and QR-PACK-2: the file holds the six modules, in
# dependency order, and the program body last. It holds no other
# package.
my @package = $code =~ /^package\s+([\w:]+)\s*;/mg;
is( "@package", PACKAGES, 'the packed file holds the six modules and the body' );

# TEST-PACK-2 and SEC-RELEASE-3: each load names a pragma, a module
# of the packed set, or Digest::SHA. A pragma starts with a lower
# case letter, and a version does as well.
my %packed = map { $_ => 1 } @package;
my @loads = $code =~ /^\s*(?:use|require)\s+([\w:]+)/mg;
my @foreign = grep {
	     !$packed{$_}
	  && !/\A[a-z]/
	  && $_ ne 'Digest::SHA'
} @loads;
is( "@foreign", q{}, 'the packed file names no module outside the packed set' );
unlike( $code, qr/(?<![\w:])Fugu::/,
	'the packed file names no Fugu:: module' );

done_testing();
