# FuguSeed

Make BIP39 seed words with three dice on paper, and back them up as a SeedQR.
`fuguseed-words` builds and checks a printed word sheet. On that sheet, one
throw of a d8 and two d16 selects one of the 2048 words, with no arithmetic. Its
manual holds the offline procedure. `fuguseed-qr` turns the 12 words into a
Standard SeedQR, zone by zone, in a terminal.

The two programs have two trust levels. `fuguseed-words` sees no seed word, so
it can run on any computer. It builds on the
[Fugu](https://github.com/FuguBSD/Fugu) library. `fuguseed-qr` sees the words,
so it must run on an air-gapped computer only. It is one packed file on core
Perl v5.34, with no dependency. FuguSeed is a companion of
[FuguPass](https://github.com/FuguBSD/FuguPass) and
[FuguOracle](https://github.com/FuguBSD/FuguOracle). The specification in
[spec/](spec/index.md) states the design.

## Commands

```sh
make deps-test   # install the runtime and the test dependencies
make check       # run every gate; run it before each commit
make test        # run every test tier
make format-fix  # fix the Perl, Markdown, JSON and YAML formatting
make dist        # build the release tarball and the packed fuguseed-qr file
```
