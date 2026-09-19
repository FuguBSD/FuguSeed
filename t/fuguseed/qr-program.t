#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The program fuguseed-qr (QR-PROGRAM, SEC-CHANNELS, SEC-TRUST-3).
# The tests run bin/fuguseed-qr as a child, and they hold each of the
# three streams and the exit code. The last part scans the source of
# the program and of every module that it loads.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use IPC::Open3       qw(open3);
use Module::CoreList ();
use Symbol           qw(gensym);
use FindBin          qw($RealBin);

my $root = "$RealBin/../..";
chdir $root or BAIL_OUT("chdir $root: $!");

use constant PROGRAM => 'bin/fuguseed-qr';
use constant OUTPUT  => 't/fuguseed/fixtures/qr/vector4.output';

# Test vector 4 of the SeedQR specification, and the word 12 of the
# vector. The BLUE row of that word holds 16 words, and one of them
# is the check word (QR-MNEMONIC-4).
use constant VECTOR =>
    'forum undo fragile fade shy sign arrest garment culture tube off merit';
use constant CHECK_WORD => 'merit';

# The child gets no PERL5LIB and no PERL5OPT of this environment, so
# no module comes from outside this checkout.
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

# _run($input, @argument):
#	Run the program with $input on standard input. The result is
#	the standard output, the standard error, and the exit code.
sub _run ( $input, @argument )
{
	local $SIG{PIPE} = 'IGNORE';
	my $fault = gensym;
	my $pid = open3( my $in, my $out, $fault, $^X, '-Ilib', PROGRAM,
		@argument );

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

# QR-PROGRAM-3 and QR-PROGRAM-4: the words on standard input give the
# SeedQR on standard output.
my ( $output, $error, $status ) = _run( VECTOR . "\n" );
is( $output, _slurp(OUTPUT), 'test vector 4 gives the fixture output' );
is( $error,  q{},            'test vector 4 writes nothing to standard error' );
is( $status, 0,              'test vector 4 exits 0' );

# QR-PROGRAM-2: an argument is a usage error (D-12).
my ( $none, $usage, $code ) = _run( q{}, 'build' );
is( $none, q{}, 'an argument gives no standard output' );
is( $usage, "usage: fuguseed-qr\n", 'an argument gives one usage line' );
is( $code, 2, 'an argument exits 2' );

# QR-PROGRAM-4 and SEC-CHANNELS-2: a failure names the position, and
# standard error carries no word.
my @words = split q{ }, VECTOR;
$words[4] = 'blorp';
my ( $empty, $line, $failure ) = _run( "@words\n" );
my @named = grep { $line =~ /\b\Q$_\E\b/ } @words;
is( $empty, q{}, 'a wrong word gives no standard output' );
is( $line, "fuguseed-qr: word 5 is not in the word list\n",
	'a wrong word gives one line that names the position' );
is( "@named", q{}, 'the failure line holds no word of the input' );
is( $failure, 1, 'a wrong word exits 1' );

my ( $short, $count, $state ) = _run("forum undo\n");
is( $count, "fuguseed-qr: the input holds 2 words, not 12\n",
	'a wrong count gives one line that names the count' );
is( $short, q{}, 'a wrong count gives no standard output' );
is( $state, 1,   'a wrong count exits 1' );

# QR-MNEMONIC-4: a wrong checksum gives the check word alone.
my @typed = split q{ }, VECTOR;
$typed[-1] = 'mercy';
my ( $word, $silent, $result ) = _run( "@typed\n" );
is( $word,   CHECK_WORD . "\n", 'a wrong checksum gives the check word' );
is( $silent, q{},               'the check word run writes nothing to standard error' );
is( $result, 0,                 'the check word run exits 0' );

# The scan. The module list comes from the program itself: a child
# loads App::FuguSeed::QR and prints %INC, so a later module of the
# program joins the scan.
open my $ph, '-|', $^X, '-Ilib', '-MApp::FuguSeed::QR', '-e',
    'print "$_\n" for sort keys %INC'
    or BAIL_OUT("$^X: $!");
my @loaded = <$ph>;
close $ph or BAIL_OUT("close $^X: status $?");
chomp @loaded;

my ( @sources, @outside );
push @sources, PROGRAM;
for my $path (@loaded) {
	( my $module = $path ) =~ s/\.pm\z//;
	$module                =~ s{/}{::}g;
	if ( $module =~ /\AApp::FuguSeed::/ ) {
		push @sources, "lib/$path";
		next;
	}
	push @outside, $module
	    unless Module::CoreList::is_core( $module, undef, 5.034 );
}
is( "@outside", q{}, 'the program loads core modules of perl 5.034 only' );

my %source = map { $_ => 1 } @sources;
my @want   = qw(
    bin/fuguseed-qr
    lib/App/FuguSeed/Codewords.pm
    lib/App/FuguSeed/List.pm
    lib/App/FuguSeed/Matrix.pm
    lib/App/FuguSeed/Mnemonic.pm
    lib/App/FuguSeed/QR.pm
    lib/App/FuguSeed/Text.pm
);
my @absent = grep { !$source{$_} } @want;
is( "@absent", q{}, 'the scan covers the program and its six modules' );

# _code($text):
#	The Perl code of $text, without the comments and the string
#	literals. A single-quoted heredoc goes first: the word list
#	of App::FuguSeed::List holds words such as "open" and "fork",
#	and the module holds the list in such a heredoc. A "#" after
#	a "$" is the last index of an array, and not a comment.
sub _code ($text)
{
	$text =~ s/<<'(\w+)';.*?^\1$//msg;
	$text =~
	    s{'[^'\\]*(?:\\.[^'\\]*)*'|"[^"\\]*(?:\\.[^"\\]*)*"|(?<!\$)\#[^\n]*}{}g;

	return $text;
}

# $contact:
#	Each builtin that opens a file or a directory, that changes
#	the file system, that starts a process, or that reaches the
#	network. SEC-TRUST-3 forbids each one.
my $contact = qr{
	\b(?: open | sysopen | opendir | readdir | closedir | rewinddir
	    | seekdir | telldir | glob | dbmopen | unlink | rename | link
	    | symlink | readlink | mkdir | rmdir | chdir | chroot | chmod
	    | chown | utime | truncate | umask | stat | lstat
	    | system | exec | fork | qx | readpipe | pipe | wait | waitpid
	    | kill | syscall
	    | socket | socketpair | bind | connect | listen | accept
	    | shutdown | recv | send | gethostbyname | getservbyname )\b
}x;

# $file_test:
#	A file test operator, such as -e or -r. Each one reads the
#	file system (SEC-TRUST-3).
my $file_test = qr{ (?<! [\w\$] ) - [rwxoRWXOezsfdlpSbctugkTBAMC] \b }x;

# $environment:
#	A read of the environment: %ENV, $ENV{...}, @ENV{...}, and
#	the getenv function of POSIX (SEC-TRUST-3).
my $environment = qr{ \b(?: ENV | getenv )\b }x;

# $dynamic:
#	A load of a file that a variable names, such as require $path
#	(SEC-TRUST-3).
my $dynamic = qr{ \b(?: do | require ) \s+ [\$\@] }x;

for my $path ( sort @sources ) {
	my $code = _code( _slurp($path) );

	# SEC-TRUST-3: the three standard streams are the one contact
	# of the program with the computer.
	my @hits = $code =~ /($contact)/g;
	push @hits, 'backtick'  if $code =~ /[`]/;
	push @hits, 'ENV'       if $code =~ $environment;
	push @hits, 'file test' if $code =~ $file_test;
	push @hits, 'load'      if $code =~ $dynamic;
	is( "@hits", q{}, "$path contacts nothing but its three streams" );

	# QR-PROGRAM-5: a source loads Digest::SHA, a pragma, and a
	# module of this repository. It loads nothing else.
	my @loads = $code =~ /^\s*(?:use|require)\s+([\w:]+)/mg;
	my @foreign = grep {
		     !/\AApp::FuguSeed::/
		  && !/\A[a-z]/
		  && $_ ne 'Digest::SHA'
	} @loads;
	is( "@foreign", q{}, "$path names no module outside this repository" );
}

done_testing();
