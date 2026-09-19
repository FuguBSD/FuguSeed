#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The install of the distribution (LIST-SHARE-2, WORDS-PROGRAM-1).
# The test builds the tarball with scripts/dist, installs it into a
# temporary prefix, and resolves the share path in that prefix.
#
# The install proves two lines of .toolingrc. Without the dist.exe
# line of bin/fuguseed-words, the prefix holds no program. Without
# the share files, the resolution finds nothing under the prefix.
# The resolution runs in a directory outside this checkout, so a
# share file of the checkout cannot answer for the installed one.
#
# The test sits outside t/fuguseed/, because .toolingrc names
# t/fuguseed alone in dist.testdir: a test that reads the checkout
# ships in no tarball (TEST-REPO-1). mk/local.mk names t/scripts/*.t
# in TEST_GLOBS.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use Config       ();
use Digest::SHA  ();
use File::Path   qw(make_path);
use File::Spec   ();
use File::Temp   ();
use IPC::Open3   qw(open3);
use Symbol       qw(gensym);
use FindBin      qw($RealBin);

my $root = "$RealBin/../..";
chdir $root or BAIL_OUT("chdir $root: $!");

# scripts/dist holds use v5.36, and the install needs the Fugu
# library of fuguseed-words (D-06).
plan skip_all => 'scripts/dist needs perl v5.36 or later' if $] < 5.036;
plan skip_all => 'the Fugu library is absent'
    unless eval { require Fugu::File; 1 };

my $make = $Config::Config{make};
plan skip_all => 'no make command'
    unless defined $make && grep { -x "$_/$make" }
    split /:/, $ENV{PATH} // q{};

use constant DIST    => 'App-FuguSeed';
use constant VERSION => '0.0.0';
use constant LIST    => 'share/fuguseed/english.txt';

# The digest of the source list (LIST-SOURCE-1). The value comes
# from spec/list.md, so the installed file answers to the
# specification, not to the checkout.
use constant DIGEST =>
    '2f5eed53a4727b4bf8880d8f3f199efc90e58503646d9ff8eff3a2ed3b24dbda';

# _run($directory, @command):
#	Run @command in $directory. The result is the two streams as
#	one text, and the exit code. The child gets no MAKEFLAGS of
#	this process: a nested make must not reach the job server of
#	the make that runs this test.
sub _run ( $directory, @command )
{
	delete local @ENV{qw(MAKEFLAGS MFLAGS MAKELEVEL)};

	my $here = File::Spec->rel2abs(q{.});
	chdir $directory or BAIL_OUT("chdir $directory: $!");

	my $fault = gensym;
	my $pid   = open3( my $in, my $out, $fault, @command );
	close $in;

	local $/ = undef;
	my $output = <$out>;
	my $error  = <$fault>;
	waitpid $pid, 0;
	my $status = $? >> 8;
	close $out;
	close $fault;

	chdir $here or BAIL_OUT("chdir $here: $!");

	return ( ( $output // q{} ) . ( $error // q{} ), $status );
}

my $work   = File::Temp->newdir;
my $prefix = File::Spec->catdir( $work, 'prefix' );
my $away   = File::Spec->catdir( $work, 'away' );
make_path($away);

# The build of the tarball.
my ( $report, $status ) = _run( $root, $^X, 'scripts/dist', '--version',
	VERSION, '--out', $work );
is( $status, 0, 'scripts/dist builds the tarball' ) or BAIL_OUT($report);

my $tarball = File::Spec->catfile( $work, DIST . q{-} . VERSION . '.tar.gz' );
ok( -f $tarball, 'the build wrote the tarball' );

( $report, $status ) = _run( $work, 'tar', '-xzf', $tarball );
is( $status, 0, 'tar extracts the tarball' ) or BAIL_OUT($report);

# The install into the temporary prefix.
my $tree = File::Spec->catdir( $work, DIST . q{-} . VERSION );
( $report, $status ) =
    _run( $tree, $^X, 'Makefile.PL', "INSTALL_BASE=$prefix" );
is( $status, 0, 'Makefile.PL writes the Makefile' ) or BAIL_OUT($report);

( $report, $status ) = _run( $tree, $make, 'install' );
is( $status, 0, 'make install fills the prefix' ) or BAIL_OUT($report);

# WORDS-PROGRAM-1: the install writes fuguseed-words into the prefix.
# The dist.exe line of .toolingrc carries that file, and without the
# line the prefix holds no program.
#
# A class name after a file test operator is a bareword filehandle on
# perl v5.34, so each path reaches a variable first.
my $installed = File::Spec->catfile( $prefix, 'bin', 'fuguseed-words' );
my $packed    = File::Spec->catfile( $prefix, 'bin', 'fuguseed-qr' );
ok( -x $installed, 'the install writes fuguseed-words into the prefix' );
ok( -x $packed,    'the install writes fuguseed-qr into the prefix' );

# LIST-SHARE-2: the share file resolves in the installed
# distribution. The child runs outside this checkout, so the share
# tree of the checkout answers for nothing here.
my $library = File::Spec->catdir( $prefix, 'lib', 'perl5' );
my ( $path, $code ) = _run( $away, $^X, "-I$library",
	'-MApp::FuguSeed::Words', '-e',
	'print App::FuguSeed::Words->share("english.txt") // q{}' );
is( $code, 0, 'the installed module resolves the share path' );
like( $path, qr/\A\Q$prefix\E\b/,
	'the resolved word list sits under the prefix' );

open my $fh, '<', $path or BAIL_OUT("$path: $!");
binmode $fh;
is( Digest::SHA->new(256)->addfile($fh)->hexdigest,
	DIGEST, 'the installed word list is the source list' );
close $fh or BAIL_OUT("close $path: $!");

# The installed program names the installed word list in its help,
# and it runs from the prefix (WORDS-PROGRAM-3).
my ( $help, $help_code ) =
    _run( $away, $^X, "-I$library", $installed, '--help' );
is( $help_code, 0, 'the installed fuguseed-words exits 0 on --help' );
like( $help, qr/\Ausage: fuguseed-words <command>/,
	'the installed fuguseed-words prints the usage line' );
like( $help, qr/The shipped word list is \Q$prefix\E/,
	'the installed fuguseed-words names the installed word list' );

done_testing();
