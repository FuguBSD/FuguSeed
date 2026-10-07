# 005 — fuguseed-last, the check word from 11 words and two dice

## Status

Proposed. The plan lands now, on its own. The implementation waits on the merge
of this plan, and it lands in one change.

Implements: LAST-PROGRAM, LAST-WORD, LAST-PACK, LAST-MANUAL, TEST-LAST.

Extends: QR-PROGRAM, QR-MNEMONIC, QR-PACK, QR-MANUAL, LIST-MODULE, SEC-TRUST,
SEC-CHANNELS, SEC-RELEASE, TEST-QR, TEST-PACK, WORDS-MANUAL.

The implementation also edits the citation-only units OVW-PURPOSE, OVW-SCOPE,
and OVW-RISKS. Their state stays `n-a`.

## Purpose

A person rolls the dice for words 1 to 11, and the YELLOW and BLUE dice for
word 12. `fuguseed-last` reads the 11 words and the two faces on standard input,
and it prints the check word. The person writes that word as word 12 and runs
`fuguseed-qr` on the 12 words. `fuguseed-qr` then only checks the checksum: a
wrong check word is a failure, and it finds no check word (D-02).

```sh
$ printf '%s\n%s\n' "<words 1 to 11>" "<yellow> <blue>" | fuguseed-last
<word 12>
```

## Constraints that shape the design

**One program, one job.** `fuguseed-last` finds the check word, and
`fuguseed-qr` encodes 12 valid words. The packed `fuguseed-qr` holds no finder,
so an auditor of it reads no dead code.

**The checksum is shared.** `App::FuguSeed::Mnemonic` keeps the word checks and
the checksum. They are the count and list check, the indexes, the bits, and the
SHA-256 of the 16 entropy bytes. The count becomes a parameter, so one check
serves 11 words and 12 words. The `check_word` method leaves `Mnemonic` and its
logic moves to `App::FuguSeed::Last`, in the form of LAST-WORD-3 and
LAST-WORD-4.

**The faces are a secret.** The YELLOW and BLUE faces of word 12 are its 7
entropy bits (D-11). They enter on the second line of standard input, and no
failure line holds a face (LAST-WORD-2). The program has no argument (D-12).

**A face has one form.** A face is a decimal number with no leading zero, so
`08` and `+8` fail. The second line holds exactly two fields.

**The packer packs two files.** `scripts/pack` holds one table row for each
packed program: the program, the module list, the header, and the output name.
One run of `scripts/dist` feeds both files. Each file gets its own header.

## Steps

Each step lands in the one implementation change.

1. Change `App::FuguSeed::Mnemonic`. Make the word count a parameter of `fault`,
   and make the checksum public. Remove `check_word`. Update the header comment
   and `Mnemonic.pod`.
2. Change `App::FuguSeed::QR`. A wrong checksum prints the failure line of
   QR-MNEMONIC-4 and returns 1. Update `QR.pod`.
3. Add `App::FuguSeed::Last` and `Last.pod`, and `bin/fuguseed-last` in the
   shape of `bin/fuguseed-qr`.
4. Change `scripts/pack` to the per-program table, and update its usage text and
   its two headers. Update the comment of `mk/local.mk`.
5. Add `fuguseed-last` to the `assets` input of `.github/workflows/release.yml`,
   and name it in the `install-note`. Add `dist.exe bin/fuguseed-last` to
   `.toolingrc`.
6. Add `man/fuguseed-last/fuguseed-last.1`. Add a `manuals` block for it to
   `.fuguwebrc`.
7. Change the procedure in `man/fuguseed/fuguseed.7`: for word 12, roll YELLOW
   and BLUE only, run `fuguseed-last`, and write its word as word 12. Remove the
   branch on two results. Update `fuguseed-qr.1` and `fuguseed-words.1`.
8. Update each comment and page that names the packed set or the programs. The
   files are `lib/App/FuguSeed.pm`, `App/FuguSeed.pod`, `List.pm`, `List.pod`,
   `Text.pod`, `Words.pm`, `deps/*.txt`, and `t/fuguseed/list.t`.
9. Update `README.md`: the second paragraph names the three programs, and the
   `make dist` line names both packed files. Keep the shape of the README.
   Update `web/index.body.html` in the same way.
10. Land the tests of the section below, and the rule texts of the next section.
11. Set LAST-PROGRAM, LAST-WORD, LAST-PACK, LAST-MANUAL, and TEST-LAST to `done`
    in `spec/STATUS.md`. Update the note of each extended unit. Delete this
    plan.

## The extended rules

The implementation lands each new text with its code. Each item below names the
rule and its new content.

- QR-PROGRAM-4: the result is the SeedQR on standard output. A wrong checksum is
  a failure (QR-MNEMONIC-4).
- QR-PROGRAM-6: `App::FuguSeed::Mnemonic` holds the word checks, the checksum,
  and the digit string.
- QR-MNEMONIC-2: a wrong checksum is a failure (QR-MNEMONIC-4).
- QR-MNEMONIC-4: on a wrong checksum, the failure line reads
  `fuguseed-qr: word 12 is not the check word`. The program prints no SeedQR.
  `fuguseed-last` finds the check word (LAST-WORD).
- QR-PACK-4: no packed file holds a part of `App::FuguSeed`.
- QR-MANUAL-1: the manual documents the one result, the SeedQR, and the failure
  of QR-MNEMONIC-4. It points at `fuguseed-last(1)` for the check word.
- LIST-MODULE-2: `fuguseed-last` and `fuguseed-qr` pack the module (D-07).
- SEC-TRUST-1: no module of `fuguseed-words` loads `App::FuguSeed::Mnemonic` or
  `App::FuguSeed::Last`.
- SEC-TRUST-2 and SEC-TRUST-3: each rule names `fuguseed-last` beside
  `fuguseed-qr`. LAST-MANUAL-2 states SEC-TRUST-2 too.
- SEC-CHANNELS-1: the words enter both programs on standard input only, and so
  do the two faces of `fuguseed-last` (D-11).
- SEC-CHANNELS-2: a failure line of either program names a position, a count, or
  a die, never a word or a face. The check word leaves `fuguseed-last` on
  standard output only.
- SEC-RELEASE-1: the release publishes `fuguseed-last` and `fuguseed-qr` beside
  the tarballs, and the signed manifest names both.
- SEC-RELEASE-2: the person compares the digest of each file. Each manual holds
  the step.
- SEC-RELEASE-3: TEST-PACK-6 holds one bound for each file. The bound of
  `fuguseed-qr` stays 1200. The bound of `fuguseed-last` is 460, about 20
  percent above the estimate of 380 lines. The rule records the measured count
  of each file.
- TEST-QR-1: the tests hold the two vectors to their digit strings, and they
  reject a wrong count and an unknown word. For each vector, each other word of
  the BLUE row of word 12 must fail with the line of QR-MNEMONIC-4.
- TEST-PACK-1, TEST-PACK-2, TEST-PACK-4, and TEST-PACK-6: each rule binds both
  packed files. TEST-PACK-1 runs `fuguseed-last` on the input of the SeedQR test
  vector 4 of TEST-LAST-1.
- TEST-PACK-3: no module of `fuguseed-words` loads `App::FuguSeed::Mnemonic` or
  `App::FuguSeed::Last`.
- WORDS-MANUAL-3: the procedure rolls YELLOW and BLUE for word 12, and no RED.
  `fuguseed-last` prints the check word, and the person writes it as word 12.
  Then `fuguseed-qr` runs on the 12 words.
- WORDS-MANUAL-5: the procedure ends with pointers to `fuguseed-last(1)` and
  `fuguseed-qr(1)`.

The citation-only units change too. OVW-PURPOSE-2 names three programs.
OVW-PURPOSE-3 adds `fuguseed-last`, and OVW-PURPOSE-4 names it as the finder.
OVW-SCOPE names the packed file `fuguseed-last`. OVW-RISKS-2 states this limit:
the search consumes the checksum of the words that the person types into
`fuguseed-last`. `fuguseed-qr` rejects a different word in its own run in 15
cases of 16. OVW-RISKS-4 names both programs.

## Tests

- `t/fuguseed/last.t` holds TEST-LAST-1 to TEST-LAST-3. It runs the program on
  standard input, and it proves the exit codes and the usage error of
  LAST-PROGRAM-2.
- `t/fuguseed/last.t` scans each source of the `fuguseed-last` module set for
  SEC-TRUST-3, like `t/fuguseed/qr-program.t`. It holds the module set to
  LAST-PROGRAM-6.
- `t/fuguseed/qr.t` and `t/fuguseed/qr-program.t` hold the new TEST-QR-1 and the
  failure of QR-MNEMONIC-4.
- `t/scripts/pack.t` holds the extended TEST-PACK rules on both files. Its
  constants and its module lists become one table for each file.
- `t/fuguseed/module.t` and `t/fuguseed/words-program.t` hold QR-PACK-4 and
  TEST-PACK-3 in their new texts.
- `t/scripts/install.t` proves that `bin/fuguseed-last` installs.

## Acceptance

- `make check` passes, and `make dist` writes `build/fuguseed-last` and
  `build/fuguseed-qr` beside the tarball.
- The five implemented units read `done`, and each extended unit stays `done`
  with an updated note.
- The first release after this change publishes both files, and the signed
  manifest names both. The operator dispatches that release.
- The change deletes this plan.

## What this plan does not do

It adds no option to any program. It changes no synced file and asks nothing of
Tooling, Fugu, or FuguPass (D-15).
