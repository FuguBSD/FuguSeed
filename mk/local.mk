# mk/local.mk: the consumer hook of this repository (MK-LOCAL).
# sync never touches this file.

# The modules and the scripts join the lint and the format scan
PERL_SRC_DIRS	= lib scripts

# make dist builds the packed fuguseed-qr file as well as the tarball
# (QR-PACK). scripts/pack runs scripts/dist first, with the same
# values, and it packs the tarball that the build writes.
DIST		= scripts/pack

# The full test tier set of make test
TEST_GLOBS	= t/fuguseed/*.t t/ci/*.t

# make man renders each manual page with mandoc (WORDS-MANUAL-6).
# t/fuguseed/man.t lints the same pages on each test run.
MANDOC		?= mandoc

man:
	@find man -type f -name '*.[1-9]' | sort | while read -r page; do \
		$(MANDOC) -Tascii "$$page" || exit 1; \
	done

.PHONY: man
