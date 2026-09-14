# Overview

FuguSeed helps one person make BIP39 seed words with three dice, on paper, and
turn them into a SeedQR. This document specifies the purpose, the scope, the
vocabulary, and the accepted limits of the project.

<a id="ovw-purpose"></a>

## Purpose

- **OVW-PURPOSE-1** — FuguSeed helps one person make 12 BIP39 seed words with
  three dice, on paper, and turn them into a Standard SeedQR.
- **OVW-PURPOSE-2** — Two programs exist, with two trust levels (D-01).
  `fuguseed-words` builds a printed word sheet from the official English word
  list, and it checks a built sheet. Its manual holds the offline procedure. It
  sees no seed word, so it can run on any computer.
- **OVW-PURPOSE-3** — `fuguseed-qr` reads 12 seed words and prints a Standard
  SeedQR as text, zone by zone, so a person can draw it on paper. It sees the
  words, so it runs on an air-gapped computer only.
- **OVW-PURPOSE-4** — No program generates a seed word (D-02). The dice give the
  entropy, the paper holds the words, and a device that accepts BIP39 words
  finds the check word.

<a id="ovw-scope"></a>

## Scope and non-goals

The scope of FuguSeed is:

- The word sheet: `fuguseed-words build` writes it, and `fuguseed-words check`
  proves it ([WORDS-BUILD](words.md#words-build),
  [WORDS-CHECK](words.md#words-check)).
- The offline procedure manual `fuguseed(7)`
  ([WORDS-MANUAL](words.md#words-manual)).
- The Standard SeedQR of 12 words, as text that a person draws
  ([QR-TEXT](qr.md#qr-text)).
- The packed single file `fuguseed-qr` for the air-gapped computer
  ([QR-PACK](qr.md#qr-pack)).

| Non-goal                    | Statement                                                                                 |
| --------------------------- | ----------------------------------------------------------------------------------------- |
| 24 words                    | No program accepts 24 words (D-04).                                                       |
| A Compact SeedQR            | No program emits a Compact SeedQR (D-04).                                                 |
| Seed generation by software | No program generates a seed word (D-02).                                                  |
| A random source             | No program holds a random source, so no audit of one exists.                              |
| A consumer function         | No function of a consumer, such as a vault or a wallet device, exists in FuguSeed (D-15). |
| Another word list           | The English list is the one word list (D-10).                                             |
| A BIP39 passphrase          | No program takes a passphrase, and the procedure holds the rule against one.              |
| A printed SeedQR template   | The repository ships no template. The manual names an external one (QR-MANUAL-4).         |

<a id="ovw-vocabulary"></a>

## Vocabulary

The project implements public standards, and its words must not narrow them to
one use (D-03).

- **OVW-VOCABULARY-1** — Every artifact names the standards that it implements,
  for example BIP39 and SeedQR. Those standards serve more than one use, and
  every artifact stays neutral between the uses.
- **OVW-VOCABULARY-2** — No file that this repository owns holds the word
  `bitcoin`, the word `crypto`, the word `cryptocurrency`, or the word `money`.
  The rule covers every letter case, singular and plural. A technical name that
  an external project fixes, such as `libcrypto`, is not a word. It sits in a
  code span, and it names the external thing only.
- **OVW-VOCABULARY-3** — A test reads the banned words from this document and
  scans every tracked file for them. The scan skips a code span, a code block,
  and a file that a pack of FuguBSD/Tooling owns. It also skips a record under
  `docs/research/` and the rule that names the words.
- **OVW-VOCABULARY-4** — The artifacts call the machine that accepts the 12
  words "the device". They call the three dice YELLOW, BLUE, and RED. They use
  "dice" for one die and for several. The device is the object that FuguPass
  calls a signer. The seed words are the BIP39 mnemonic of FuguPass.

<a id="ovw-risks"></a>

## Risks and limits

- **OVW-RISKS-1** — A hand-drawn code can misdecode. The scan on the device and
  the scan in the consumer are the proof of the drawing, and no other proof
  exists.
- **OVW-RISKS-2** — The trial of the check word on the device consumes the
  checksum, so the checksum detects no error in words 1 to 11. The person
  compares the device with the paper before any use (WORDS-MANUAL-4).
- **OVW-RISKS-3** — A biased die lowers the entropy a little. The dice are the
  one source of entropy, and no program measures them or corrects them.
- **OVW-RISKS-4** — `fuguseed-qr` trusts the computer that it runs on. The air
  gap is the whole defense ([SEC-TRUST](security.md#sec-trust)).
