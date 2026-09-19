# 004 — fuguseed-words, the sheet and the procedure

## Status

Proposed. It waits on plan 001 for the list, and on plan 002 for the `man`
target and the mandoc test. It also waits on plan 003 for TEST-PACK-1 and
TEST-PACK-2.

Implements: WORDS-PROGRAM, WORDS-BUILD, WORDS-CHECK, TEST-SHEET. Implements:
WORDS-MANUAL without WORDS-MANUAL-6. Implements: LIST-SHARE, SEC-TRUST,
TEST-PACK.

Of LIST-SHARE, SEC-TRUST, and TEST-PACK, this plan lands LIST-SHARE-2 and
LIST-SHARE-3, SEC-TRUST-1, and TEST-PACK-3. The other rules of those units come
from plan 001, plan 002, and plan 003. Plan 002 lands WORDS-MANUAL-6, the `man`
target, so this plan lands the other five rules of that unit.

## Purpose

`fuguseed-words` builds the printed word sheet, checks a built sheet, and holds
the offline procedure in its manuals. It sees no seed word, so it can run on any
computer and build on the Fugu library (D-01, D-06). This plan lands the
program, its two verbs, the two share files of the sheet, the two manuals, and
the tests.

## Constraints that shape the design

**The checker owes the builder nothing.** `App::FuguSeed::Sheet` builds the
sheet, and `App::FuguSeed::Check` proves one. The checker loads no builder
module (WORDS-CHECK-3). It consumes the sheet as one strict grammar from the
first byte to the last. It names the byte offset of the first unexpected byte
(WORDS-CHECK-4). The grammar is the exact token sequence of the shipped
template, with the 2048 cells and the labels as the variable parts.

**The sheet is the address space.** Block `Y`, row `B`, and column `R` hold the
word of index `(Y-1)*256 + (B-1)*16 + (R-1)` (D-05, WORDS-BUILD-6). The
captions, the headers, and the legend name the dice by color, so a black print
keeps the names.

**The sheet holds no place for a decoy.** Class-less HTML5, no `class`, `id`,
`style`, `dir`, or `hidden` attribute, no script, no comment, no entity, and
printable ASCII only (WORDS-BUILD-3). The build inlines `sheet.css`, and the
check compares the inlined text with the shipped file byte for byte (D-09).

**A list argument proves its digest.** Both verbs take a list file. One module,
`App::FuguSeed::ListFile`, reads it, computes its SHA-256, and refuses another
digest than `App::FuguSeed::List::DIGEST` (LIST-SHARE-3). The share files
resolve through `Fugu::File->share_path`, in a checkout and after an install
(LIST-SHARE-2).

**The program never maps 12 words.** No module of the program loads
`App::FuguSeed::Mnemonic` (SEC-TRUST-1), and a test scans the sources for it
(TEST-PACK-3).

## The interface contract

- `fuguseed-words build <list> [--date YYYY-MM-DD]` writes the sheet as HTML to
  standard output. Two builds of one list on one date are byte-equal.
- `fuguseed-words check <sheet> <list>` is silent on success and exits 0. On a
  failure it prints one defect per line on standard error and exits 1.
- `--help` on the program and on each verb prints the usage and exits 0. A
  command line without a verb is a usage error with exit 2 (Fugu LIB-CLI).
- Standard output carries the result of a verb only. Every diagnostic goes to
  standard error through `Fugu::Log` in stderr mode.

## Files

| File                                  | Change                                                                    |
| ------------------------------------- | ------------------------------------------------------------------------- |
| `bin/fuguseed-words`                  | The program: `App::FuguSeed::Words->run(@ARGV)`                           |
| `lib/App/FuguSeed/Words.pm`           | The `Fugu::CLI` dispatch of `build` and `check`                           |
| `lib/App/FuguSeed/ListFile.pm`        | The list file reader and its digest check                                 |
| `lib/App/FuguSeed/Sheet.pm`           | The builder (WORDS-BUILD-8)                                               |
| `lib/App/FuguSeed/Check.pm`           | The checker (WORDS-CHECK)                                                 |
| `lib/App/FuguSeed/*.pod`              | One sidecar per module                                                    |
| `share/fuguseed/sheet.html`           | The template                                                              |
| `share/fuguseed/sheet.css`            | The style sheet: selection by element and structure only                  |
| `man/fuguseed-words/fuguseed-words.1` | The program manual and the print instructions                             |
| `man/fuguseed/fuguseed.7`             | The offline procedure in ASD-STE100                                       |
| `t/fuguseed/sheet.t`                  | The tests below                                                           |
| `t/fuguseed/words-program.t`          | The program tests below                                                   |
| `t/fuguseed/fixtures/sheet.html`      | The sheet of the shipped list on the fixed date                           |
| `t/scripts/install.t`                 | The install test below                                                    |
| `.toolingrc`                          | One `dist.share-extra` line for the sheet fixture                         |
| `spec/STATUS.md`                      | The cited units, and `t/scripts/install.t` in the Code roots of `list.md` |

`.toolingrc` names the sheet fixture in `dist.share-extra`, because
`scripts/dist` copies a test file only.

The procedure page follows WORDS-MANUAL-2 to WORDS-MANUAL-5. Its sections are
the equipment and the names, the steps before the start, and how to find one
word. Then words 1 to 11, word 12 with `fuguseed-qr`, and the steps after
follow. It holds the WARNING of D-14 and the note on the faces 6 and 9. It holds
the rule against a BIP39 passphrase. It ends with the pointer to
`fuguseed-qr(1)` and names no software for the roll of the dice.

## Tests

`t/fuguseed/sheet.t` holds:

- A build of the shipped list on a fixed date equals its fixture, and two builds
  are byte-equal (WORDS-BUILD-7).
- The check passes on the built sheet (TEST-SHEET-1).
- The check fails on each corrupted sheet of TEST-SHEET-1. The set holds a wrong
  word, a swapped pair, a wrong label, a duplicated block, and an extra
  attribute. It holds a comment, a script, a soft hyphen, a changed style rule,
  and a wrong footer digest. Each failure names a byte offset or a position.
- The list reader refuses a list with another digest (LIST-SHARE-3).
- The share files resolve in the checkout (LIST-SHARE-2).

`t/scripts/install.t` builds the distribution with
`scripts/dist --out <temporary directory>`, installs it into a temporary prefix,
and resolves the share path there (LIST-SHARE-2). It sits outside `t/fuguseed/`,
because `.toolingrc` names `t/fuguseed` alone in `dist.testdir`, and
`mk/local.mk` names `t/scripts/*.t` in `TEST_GLOBS`.

`t/fuguseed/words-program.t` runs the program as a child and holds:

- The exit codes and the streams of the contract above.
- No source file under `lib/App/FuguSeed/` that the program loads names
  `App::FuguSeed::Mnemonic` (TEST-PACK-3).

The mandoc test of plan 002 covers the two new pages.

## Acceptance

- `make check` passes, and `make man` renders the three pages.
- Every cited unit reads `done`, with links to the code and the tests.
- The change deletes this plan.

## What this plan does not do

It ships no printed SeedQR template: the manual of plan 002 names the external
one (QR-MANUAL-4). It rolls no dice and finds no word.
