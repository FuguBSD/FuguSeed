# 002 — fuguseed-qr, the words to a Standard SeedQR

## Status

Proposed. It waits on plan 001 for the list module. Plan 003 waits on it for the
modules that the packer lists. Plan 004 waits on it for the `man` target and the
mandoc test.

Implements: QR-PROGRAM, QR-MNEMONIC, QR-CODEWORDS, QR-MATRIX, QR-TEXT,
QR-MANUAL, TEST-QR, TEST-MANUAL, SEC-CHANNELS. Implements: SEC-TRUST without
SEC-TRUST-1. Implements: WORDS-MANUAL without WORDS-MANUAL-1, WORDS-MANUAL-2,
WORDS-MANUAL-3, WORDS-MANUAL-4, and WORDS-MANUAL-5. Defers: QR-PACK,
SEC-RELEASE.

SEC-TRUST-1 binds `fuguseed-words`, so plan 004 lands it. Plan 003 packs the
program and releases the file. This plan lands the `man` target that
WORDS-MANUAL-6 names, because the first page appears here. WORDS-MANUAL-1 to
WORDS-MANUAL-5 bind the manuals of `fuguseed-words`, so plan 004 lands them.

## Purpose

`fuguseed-qr` reads 12 seed words on standard input and prints a Standard SeedQR
as text, zone by zone. A person draws it on paper. It is the one program of
FuguSeed that sees the words. This plan lands the program, its five modules, its
tests, and its manual. FuguPass reads the SeedQR that this program prints, and
it reads no typed word, so this program is the handoff between the two projects.

## Constraints that shape the design

**Every function is pure.** `App::FuguSeed::Mnemonic` turns 12 words into the
digit string. `App::FuguSeed::Codewords` turns the digits into the 44 codewords.
`App::FuguSeed::Matrix` places them in the 25 x 25 grid. `App::FuguSeed::Text`
renders the grid view and the zone views. `App::FuguSeed::QR` holds the flow and
the three standard streams. No other module touches a stream.

**The program trusts nothing but its streams.** The modules load `Digest::SHA`
and no other module outside this repository (QR-PROGRAM-5). They open no file,
spawn no process, and read no environment variable (SEC-TRUST-3). A test scans
the module sources for the builtins that break this rule.

**The mask is pattern 0.** The program evaluates no penalty score (D-08). The
format information is the 15 bits of QR-MATRIX-5, in both positions. The
reference image of test vector 4 of the SeedQR specification is mask 0, so one
picture proves the whole pipeline.

**A failure names a position, never a word.** The one failure line on standard
error names the word position, the count, or the checksum (SEC-CHANNELS-2). An
argument is a usage error with exit 2 (QR-PROGRAM-2).

**The pause reads one line per zone.** After each zone view, the program reads
one line from standard input before the next zone. At the end of the input, the
remaining zones print without a pause (QR-TEXT-5). The tests pipe the 12 words
and nothing else, so every zone prints at once.

## The interface contract

The program takes no option and no argument. The first line of standard input
holds the 12 words, separated by spaces. Standard output holds the digit string
of QR-MNEMONIC-3 on one line, then the grid view. The 25 zone views follow, in
the order `A-1` to `E-5`. A dark module prints as `#`, and a light module prints
as `.`. Exit 0 on success, 1 on a failure, and 2 on a usage error.

## Files

| File                            | Change                                                          |
| ------------------------------- | --------------------------------------------------------------- |
| `bin/fuguseed-qr`               | The program: it calls `App::FuguSeed::QR->run` only             |
| `lib/App/FuguSeed/Mnemonic.pm`  | The words: count, list membership, checksum, digits             |
| `lib/App/FuguSeed/Codewords.pm` | The bit stream, the pad bytes, the Reed-Solomon remainder       |
| `lib/App/FuguSeed/Matrix.pm`    | The function patterns, the placement, the mask, the format bits |
| `lib/App/FuguSeed/Text.pm`      | The grid view and the zone views                                |
| `lib/App/FuguSeed/QR.pm`        | The flow: read, encode, print, pause                            |
| `lib/App/FuguSeed/*.pod`        | One sidecar per module                                          |
| `man/fuguseed-qr/fuguseed-qr.1` | The manual (QR-MANUAL)                                          |
| `mk/local.mk`                   | The `man` target: `mandoc -Tascii` on each page                 |
| `deps/Linux.txt`                | `mandoc`, for the CI runner                                     |
| `t/fuguseed/qr.t`               | The pipeline tests below                                        |
| `t/fuguseed/qr-program.t`       | The program tests below                                         |
| `t/fuguseed/man.t`              | `mandoc -Tlint` on each page under `man` (TEST-MANUAL)          |
| `t/fuguseed/fixtures/qr/`       | The picture and the text fixtures of test vector 4              |
| `spec/STATUS.md`                | The cited units                                                 |

Each constant of the QR standard sits at the top of the module that uses it. A
comment names the table of the standard (QR-PROGRAM-7).

## Tests

`t/fuguseed/qr.t` holds:

- The two 12-word test vectors of the SeedQR specification give their digit
  strings. A wrong count, an unknown word, and a wrong checksum fail, and each
  failure names the position (TEST-QR-1).
- The 44 codewords of test vector 4 equal the values that its reference image
  implies (TEST-QR-2).
- The matrix of test vector 4 equals the picture of its reference image, module
  for module. The picture sits in the fixture as 25 rows of `#` and `.`
  (TEST-QR-3).
- Both matrices hold the 127 dark function modules of QR-MATRIX-2, and the 15
  format bits sit in both positions (TEST-QR-4).
- The grid view and the zone views of test vector 4 equal their fixtures. Each
  zone count equals the count in the matrix (TEST-QR-5).

`t/fuguseed/qr-program.t` runs `bin/fuguseed-qr` as a child and holds:

- Test vector 4 on standard input gives the fixture output and exit 0.
- An argument gives one usage line on standard error and exit 2.
- A wrong word gives one line on standard error that names the position and
  holds no word of the input, and exit 1.
- The scan covers the six files of this plan and `lib/App/FuguSeed/List.pm`. It
  takes the module list of the program, so a later module joins it. Each source
  loads `Digest::SHA` and modules of this repository only. Each source holds no
  `open`, `opendir`, `system`, `exec`, `fork`, backtick, `qx`, or `%ENV`
  (SEC-TRUST-3, QR-PROGRAM-5).

`t/fuguseed/man.t` runs `mandoc -Tlint` on each page under `man` and requires an
empty report (TEST-MANUAL-1).

## Acceptance

- `make check` passes, and `make man` renders the page.
- Every cited unit reads `done`, except SEC-TRUST and WORDS-MANUAL. SEC-TRUST
  reads `partial` with SEC-TRUST-1 as the absent part. WORDS-MANUAL reads
  `partial` with WORDS-MANUAL-1, WORDS-MANUAL-2, WORDS-MANUAL-3, WORDS-MANUAL-4,
  and WORDS-MANUAL-5 as the absent parts.
- The change deletes this plan.

## What this plan does not do

It packs nothing: `bin/fuguseed-qr` runs from the checkout with `lib` on the
include path, and plan 003 makes the one-file release. It builds no sheet.
