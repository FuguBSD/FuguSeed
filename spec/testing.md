# Testing

The tests prove the specification. This document holds every rule that binds the
tests: the word list, the sheet, the SeedQR pipeline, the packed file, and the
manuals. Each unit that a test proves points here.

<a id="test-list"></a>

## The word list

- **TEST-LIST-1** — One test must compute the SHA-256 of the embedded words of
  `App::FuguSeed::List` and of the share file. Both must equal the constant of
  LIST-MODULE-1.
- **TEST-LIST-2** — One test must prove LIST-SOURCE-2 and LIST-SOURCE-3 on the
  embedded words.

<a id="test-sheet"></a>

## The sheet

- **TEST-SHEET-1** — The tests must run the check verb on a built sheet and on a
  set of corrupted sheets. The set holds a wrong word, a swapped pair, a wrong
  label, a duplicated block, and an extra attribute. It holds a comment, a
  script, a soft hyphen, a changed style rule, and a wrong footer digest. Each
  corrupted sheet must fail.

<a id="test-qr"></a>

## The SeedQR

- **TEST-QR-1** — The tests must hold the two 12-word test vectors of the SeedQR
  specification to their digit strings. They must reject a wrong count and an
  unknown word. For each vector, they must replace word 12 with each other word
  of its BLUE row. They must prove that the program names word 12 of the vector
  as the check word.
- **TEST-QR-2** — The tests must hold the 44 codewords of test vector 4 to the
  values that the reference image of the SeedQR specification implies.
- **TEST-QR-3** — The tests must hold the matrix of test vector 4 to the
  reference image of the SeedQR specification, module for module. The fixture
  `t/fuguseed/fixtures/qr/vector4.picture` must hold the picture of that image,
  as 25 rows of `#` and `.`.
- **TEST-QR-4** — The tests must prove QR-MATRIX-2 on the matrix of both test
  vectors. They must prove that the 15 format bits sit in both positions.
- **TEST-QR-5** — The tests must hold the grid view and the zone views of test
  vector 4 to fixtures. They must prove the zone counts against the matrix. They
  must prove that the program reads one line of standard input between two zone
  views (QR-TEXT-5).

<a id="test-pack"></a>

## The packed file

- **TEST-PACK-1** — The tests must run the packed file with an `@INC` that holds
  the core library alone, with test vector 4 on standard input. They run it on
  the running perl, and on `/usr/bin/perl` when it exists.
- **TEST-PACK-2** — The tests must prove that the packed file names no module
  outside the core of perl 5.34 and no `Fugu::` module.
- **TEST-PACK-3** — The tests must prove that no module of `fuguseed-words`
  loads `App::FuguSeed::Mnemonic` (SEC-TRUST-1).
- **TEST-PACK-4** — The tests must hold the text of the packed file to its
  parts. The parts are the header of `scripts/pack`, one frame for each module,
  and the program body. They must hold the first line of the file to the literal
  `#!/usr/bin/perl`. They must hold the packed set to the modules that
  `fuguseed-qr` loads.
- **TEST-PACK-5** — One test must load `App::FuguSeed` and prove QR-PACK-4 on
  its source. The source must hold the package name that PAUSE indexes, and no
  code.
- **TEST-PACK-6** — The tests must count the lines of the packed file outside
  the word list block of LIST-MODULE-1. That count must stay below the bound
  that SEC-RELEASE-3 gives.

<a id="test-manual"></a>

## The manuals

- **TEST-MANUAL-1** — A test must prove that `mandoc -Tlint` reports no error on
  any page under `man`.
