# 001 — The word list

## Status

Proposed. It can land now, and it depends on no other plan. Plan 002 and plan
004 wait on it: both programs read the list through this module or this file.

Implements: LIST-SHARE without LIST-SHARE-2 and LIST-SHARE-3. Implements:
LIST-MODULE, TEST-LIST.

LIST-SHARE-2 and LIST-SHARE-3 bind a program that reads a list file. Plan 004
lands them with `fuguseed-words`.

## Purpose

Both programs read the official English word list of BIP39 (D-10). The list has
two shipped copies. A person can inspect and replace the share file. The module
that `fuguseed-qr` packs holds the embedded copy. This plan lands the two copies
and the one test that holds both to the pinned SHA-256 of LIST-SOURCE-1.

## Constraints that shape the design

**The module packs.** `App::FuguSeed::List` runs on core Perl v5.34 with no
dependency (LIST-MODULE-2), so `scripts/pack` can embed it. The words sit in one
single-quoted heredoc, one word per line. A `__DATA__` section cannot serve: a
packed file holds several modules, and only one data section can exist.

**The module opens no file.** `fuguseed-qr` and every module that it loads open
no file (SEC-TRUST-3). The module therefore reads no share file. The digest
check of a list file lives with `fuguseed-words`, in plan 004.

**One digest pins both copies.** The module holds the SHA-256 of LIST-SOURCE-1
as one constant. The test computes the digest of the embedded words and of the
share file, and both must equal the constant. FuguPass pins its own C word table
to the same digest, so the two projects agree on the list by one number.

## The interface contract

- `App::FuguSeed::List->word($index)` returns the word of a 0-based index, or
  `undef` outside 0 to 2047.
- `App::FuguSeed::List->index($word)` returns the 0-based index of a word, or
  `undef` for an unknown word.
- `App::FuguSeed::List->words` returns the 2048 words as a list.
- `App::FuguSeed::List::DIGEST` is the SHA-256 of LIST-SOURCE-1, as lowercase
  hex.

## Files

| File                         | Change                                                     |
| ---------------------------- | ---------------------------------------------------------- |
| `share/fuguseed/english.txt` | The list, byte for byte equal to the source (LIST-SHARE-1) |
| `lib/App/FuguSeed/List.pm`   | The module: the heredoc, the constant, the three functions |
| `lib/App/FuguSeed/List.pod`  | The sidecar                                                |
| `t/fuguseed/list.t`          | The tests below                                            |
| `spec/STATUS.md`             | LIST-SHARE `partial`, LIST-MODULE and TEST-LIST `done`     |

## Tests

`t/fuguseed/list.t` holds:

- The SHA-256 of the embedded words, joined with one line feed after each word,
  equals the constant (TEST-LIST-1).
- The SHA-256 of `share/fuguseed/english.txt` equals the constant (TEST-LIST-1).
- The embedded list holds 2048 words of 3 to 8 lowercase ASCII letters. The
  words are unique and sorted, and the first four letters of each word are
  unique (TEST-LIST-2).
- `word`, `index`, and `words` answer as the contract states, and an unknown
  word or an index outside the range gives `undef`.
- The module loads with `Digest::SHA` as its one module outside this repository.

## Acceptance

- `make check` passes.
- LIST-MODULE and TEST-LIST read `done`, with links to the module and the test.
  LIST-SHARE reads `partial`, and its note names LIST-SHARE-2 and LIST-SHARE-3
  as the parts that wait on WORDS-BUILD and WORDS-CHECK.
- The change deletes this plan.

## What this plan does not do

It builds no sheet and no SeedQR. It reads no list file at run time: the digest
check of a list argument is the work of plan 004.
