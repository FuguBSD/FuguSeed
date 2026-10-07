# Security

The seed words are the whole secret. This document specifies the trust rules of
the three programs (D-01) and the channels that carry the words (D-11). It also
specifies the release of the packed files (D-07).

<a id="sec-trust"></a>

## The trust levels

- **SEC-TRUST-1** — `fuguseed-words` must accept no seed word on any channel,
  and it must hold no code that maps seed words to anything. No module of the
  program loads `App::FuguSeed::Mnemonic` or `App::FuguSeed::Last`
  ([TEST-PACK](testing.md#test-pack)).
- **SEC-TRUST-2** — `fuguseed-last` and `fuguseed-qr` must run on an air-gapped
  computer only. Each manual states the rule (LAST-MANUAL-2, QR-MANUAL-2).
- **SEC-TRUST-3** — `fuguseed-last`, `fuguseed-qr`, and every module that they
  load open no file, spawn no process, and read no environment variable. The
  three standard streams are the one contact of each program with the computer.

<a id="sec-channels"></a>

## The channels

- **SEC-CHANNELS-1** — The words enter `fuguseed-last` and `fuguseed-qr` on
  standard input only, and so do the two faces of `fuguseed-last` (D-11). No
  argument, no file name, and no environment variable carries a word or a face.
- **SEC-CHANNELS-2** — A failure line of either program can name a word
  position, a count, or a die, never a word or a face. Standard error carries no
  word and no face. The check word leaves `fuguseed-last` on standard output
  only (LAST-PROGRAM-4).

<a id="sec-release"></a>

## The release

- **SEC-RELEASE-1** — The release workflow publishes `fuguseed-last` and
  `fuguseed-qr` beside the tarballs, and the signed `SHA256` manifest of the
  release names both.
- **SEC-RELEASE-2** — The person compares the digest of each file with the
  manifest on the air-gapped computer, before the first run. Each manual holds
  the step (LAST-MANUAL-1, QR-MANUAL-1).
- **SEC-RELEASE-3** — Each file is short enough for one person to read in full
  (D-07). It holds the modules of this repository alone, so no dependency
  crosses to the air-gapped computer with it. No part of a file checks another
  part. The signed manifest of SEC-RELEASE-2 is the one check of its bytes.
  TEST-PACK-6 counts the lines of each file outside the word list block of
  LIST-MODULE-1. The block holds the 2048 words of LIST-SOURCE-1, and its length
  does not change, so the count measures the rest of the file. The count of
  `fuguseed-qr` is 993 lines, and its bound of 1200 is 207 lines above it. The
  count of `fuguseed-last` is 397 lines, and its bound of 460 is 63 lines above
  it.
