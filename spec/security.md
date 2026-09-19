# Security

The seed words are the whole secret. This document specifies the trust rules of
the two programs (D-01) and the channels that carry the words (D-11). It also
specifies the release of the packed file (D-07).

<a id="sec-trust"></a>

## The trust levels

- **SEC-TRUST-1** — `fuguseed-words` must accept no seed word on any channel,
  and it must hold no code that maps 12 words to anything. No module of the
  program loads `App::FuguSeed::Mnemonic` ([TEST-PACK](testing.md#test-pack)).
- **SEC-TRUST-2** — `fuguseed-qr` must run on an air-gapped computer only. The
  manual states the rule (QR-MANUAL-2).
- **SEC-TRUST-3** — `fuguseed-qr` and every module that it loads open no file,
  spawn no process, and read no environment variable. The three standard streams
  are its one contact with the computer.

<a id="sec-channels"></a>

## The channels

- **SEC-CHANNELS-1** — The 12 words enter `fuguseed-qr` on standard input only
  (D-11). No argument, no file name, and no environment variable carries a word.
- **SEC-CHANNELS-2** — A failure line of `fuguseed-qr` names the word position
  that failed, never a word. Standard error carries no word. The check word
  leaves on standard output only (QR-MNEMONIC-4).

<a id="sec-release"></a>

## The release

- **SEC-RELEASE-1** — The release workflow publishes `fuguseed-qr` beside the
  tarballs, and the signed `SHA256` manifest of the release names it.
- **SEC-RELEASE-2** — The person compares the digest of the file with the
  manifest on the air-gapped computer, before the first run. The manual holds
  the step (QR-MANUAL-1).
- **SEC-RELEASE-3** — The file is short enough for one person to read in full
  (D-07). It holds the modules of this repository alone, so no dependency
  crosses to the air-gapped computer with it. The word list of LIST-MODULE-1 is
  one block of 2048 lines, and the `DIGEST` constant beside it pins that block.
  The person reads the lines outside the block, and TEST-PACK-6 holds that count
  below a bound.
