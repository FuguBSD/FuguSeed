# fuguseed-last

`fuguseed-last` reads seed words 1 to 11 and the YELLOW and BLUE faces of word
12, and it prints the check word. It sees the words, so it runs on an air-gapped
computer only (D-01, [SEC-TRUST](security.md#sec-trust)). This document
specifies the program, the input, the check word, the packed release, and the
manual.

<a id="last-program"></a>

## The program

- **LAST-PROGRAM-1** — The program is `bin/fuguseed-last`. It holds no logic: it
  calls `App::FuguSeed::Last->run` and exits with the result.
- **LAST-PROGRAM-2** — The program takes no option and no argument (D-12). An
  argument is a usage error: the program prints one usage line to standard error
  and exits 2.
- **LAST-PROGRAM-3** — The program reads two lines of standard input
  ([SEC-CHANNELS](security.md#sec-channels)). The first line holds words 1
  to 11. The second line holds the YELLOW face and the BLUE face of word 12. One
  or more spaces separate two fields of a line, as in QR-PROGRAM-3.
- **LAST-PROGRAM-4** — The program writes the check word on one line of standard
  output and exits 0. A failure prints one exact line to standard error and
  exits 1 ([SEC-CHANNELS](security.md#sec-channels)).
- **LAST-PROGRAM-5** — The program and every module that it loads run on core
  Perl v5.34 (D-07). They load `Digest::SHA` and no other module outside this
  repository ([SEC-TRUST](security.md#sec-trust)).
- **LAST-PROGRAM-6** — The program loads three modules of this repository. The
  modules are `App::FuguSeed::List`, `App::FuguSeed::Mnemonic`, and
  `App::FuguSeed::Last`. `App::FuguSeed::Mnemonic` holds only the functions that
  both programs call: the word checks, the indexes, and the checksum.
  `App::FuguSeed::Last` holds the face check, the check word, and the flow.
  Every function is pure: it takes values and returns values.

<a id="last-word"></a>

## The check word

- **LAST-WORD-1** — The first line must hold exactly 11 words. Each word must be
  in the list of LIST-MODULE-1. Another count or an unknown word is a failure.
  The failure line names the count or the word position.
- **LAST-WORD-2** — The second line must hold exactly two fields. Another count
  is a failure, and a missing second line holds no field. The failure line names
  the field count. A face is a decimal number with no sign and no leading zero.
  The YELLOW face must be 1 to 8, and the BLUE face must be 1 to 16 (D-05).
  Another form or a face out of its range is a failure. The failure line names
  the die, never the face.
- **LAST-WORD-3** — The row of word 12 starts at the index
  `(Y-1)*256 + (B-1)*16` (D-05). The 11 indexes give 121 bits, and the 7 high
  bits of the row give the last 7 bits of the 128 entropy bits.
- **LAST-WORD-4** — The check word is the word of the index that is the start of
  the row plus the checksum. The checksum is the first 4 bits of the SHA-256 of
  the 16 entropy bytes, as BIP39 states (D-02).

The tests of this unit live in [TEST-LAST](testing.md#test-last).

<a id="last-pack"></a>

## The packed release

- **LAST-PACK-1** — `scripts/pack` writes `build/fuguseed-last` beside
  `build/fuguseed-qr`. The file holds the program of LAST-PROGRAM-1 and the
  modules of LAST-PROGRAM-6, and no other module.
- **LAST-PACK-2** — The first line rule of QR-PACK-1 holds for the file. The
  packer rules of QR-PACK-2 and the byte equality of QR-PACK-3 hold for it too.

The release of the file lives in [SEC-RELEASE](security.md#sec-release), and its
tests in [TEST-PACK](testing.md#test-pack).

<a id="last-manual"></a>

## The manual

- **LAST-MANUAL-1** — `man/fuguseed-last/fuguseed-last.1` documents the program,
  the two input lines, the exit codes, and the digest check of SEC-RELEASE-2.
- **LAST-MANUAL-2** — The manual states that the program must run on an
  air-gapped computer only (SEC-TRUST-2). It is in ASD-STE100 (D-13).
- **LAST-MANUAL-3** — The manual states the next step: the person writes the
  check word as word 12, then runs `fuguseed-qr` on the 12 words.
- **LAST-MANUAL-4** — The manual states that the program cannot find a wrong
  word in words 1 to 11. The check word makes the checksum valid for any 11
  words of the list. When the paper holds the same wrong word, `fuguseed-qr`
  cannot find it either.
