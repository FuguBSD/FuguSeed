# fuguseed-qr

`fuguseed-qr` reads 12 seed words and prints a Standard SeedQR as text, so a
person can draw it on paper. It sees the words, so it runs on an air-gapped
computer only (D-01, [SEC-TRUST](security.md#sec-trust)). The format is the
SeedQR specification of the SeedSigner project. This document specifies the
program, the word check, the QR encoding, the text output, the packed release,
and the manual.

<a id="qr-program"></a>

## The program

- **QR-PROGRAM-1** — The program is `bin/fuguseed-qr`. It holds no logic: it
  calls `App::FuguSeed::QR->run` and exits with the result.
- **QR-PROGRAM-2** — The program takes no option and no argument (D-12). An
  argument is a usage error: the program prints one usage line to standard error
  and exits 2.
- **QR-PROGRAM-3** — The program reads the 12 words from the first line of
  standard input, separated by spaces
  ([SEC-CHANNELS](security.md#sec-channels)).
- **QR-PROGRAM-4** — The program writes the result to standard output: the
  SeedQR text, or the check word when the checksum fails (QR-MNEMONIC-4). A
  failure prints one exact line to standard error and exits 1
  ([SEC-CHANNELS](security.md#sec-channels)).
- **QR-PROGRAM-5** — The program and every module that it loads run on core Perl
  v5.34 (D-07). They load `Digest::SHA` and no other module outside this
  repository ([SEC-TRUST](security.md#sec-trust)).
- **QR-PROGRAM-6** — Each module of the program has one concern.
  `App::FuguSeed::Mnemonic` holds the words. `App::FuguSeed::Codewords` holds
  the data and error correction codewords. `App::FuguSeed::Matrix` holds the
  module grid. `App::FuguSeed::Text` holds the output, and `App::FuguSeed::QR`
  holds the flow. Every function is pure: it takes values and returns values.
- **QR-PROGRAM-7** — Every constant of the QR standard sits at the top of the
  module that uses it. A comment names the table of the standard that it comes
  from.

<a id="qr-mnemonic"></a>

## The seed words

- **QR-MNEMONIC-1** — The input must hold exactly 12 words. Each word must be in
  the list of LIST-MODULE-1. Another count or an unknown word is a failure.
- **QR-MNEMONIC-2** — The 12 indexes give 132 bits: 128 bits of entropy and 4
  bits of checksum. The checksum must equal the first 4 bits of the SHA-256 of
  the 16 entropy bytes, as BIP39 states. A wrong checksum is not a failure: the
  program finds the check word (QR-MNEMONIC-4).
- **QR-MNEMONIC-3** — The digit string is the 12 indexes, 0-based, each as 4
  decimal digits with leading zeros, in word order: 48 digits.
- **QR-MNEMONIC-4** — When the checksum fails, the program must find the check
  word (D-02). The YELLOW block and the BLUE row of the typed word 12 give 7
  bits of entropy. The RED column gives the 4 checksum bits, so exactly one word
  of that row is valid. The program must print that word on standard output and
  exit 0. It prints no SeedQR in that run.

The tests of this unit live in [TEST-QR](testing.md#test-qr).

<a id="qr-codewords"></a>

## The codewords

- **QR-CODEWORDS-1** — The code is QR version 2, error correction level L, in
  numeric mode (D-04). It holds 44 codewords in one block: 34 of data and 10 of
  error correction.
- **QR-CODEWORDS-2** — The data bit stream starts with the mode indicator `0001`
  and the character count 48 as 10 bits. The 48 digits follow in 16 groups of 3
  digits, as 10 bits each. The terminator `0000` follows, then zero bits to a
  byte boundary. The pad bytes `0xEC` and `0x11` fill the stream in turn to 34
  bytes.
- **QR-CODEWORDS-3** — The 10 error correction codewords are the Reed-Solomon
  remainder of the 34 data codewords over GF(256). The field polynomial is
  `0x11D`, and the generator polynomial is the degree 10 polynomial of the QR
  standard.

The tests of this unit live in [TEST-QR](testing.md#test-qr).

<a id="qr-matrix"></a>

## The matrix

- **QR-MATRIX-1** — The matrix is 25 x 25 modules. Module `(0,0)` is the top
  left corner, the first index is the row, and the second is the column.
- **QR-MATRIX-2** — The function patterns are the three finder patterns with
  their separators, and the timing patterns in row 6 and column 6. The alignment
  pattern centers on `(18,18)`, and the dark module sits at `(17,8)`. Together
  they hold 127 dark modules, the same for every 25 x 25 code.
- **QR-MATRIX-3** — The 352 codeword bits fill the matrix in the placement order
  of the QR standard. The order starts at the bottom right and runs in column
  pairs, upward and downward in turn, over column 6. The 7 remainder bits are 0.
- **QR-MATRIX-4** — The mask is pattern 0 (D-08): a data module at `(r,c)`
  inverts when `(r + c) mod 2` is 0. No function module and no format module
  inverts.
- **QR-MATRIX-5** — The format information is the 15 bits `111011111000100`, for
  level L and mask 0, in the two positions of the QR standard. The code holds no
  version information.

The tests of this unit live in [TEST-QR](testing.md#test-qr).

<a id="qr-text"></a>

## The text output

- **QR-TEXT-1** — A dark module prints as `#`, and a light module prints as `.`.
  One character is one module.
- **QR-TEXT-2** — The output starts with the digit string of QR-MNEMONIC-3 on
  one line. Then the grid view follows: the 25 rows, with one space between the
  zone columns and one empty line between the zone rows. The row letters A to E
  and the column numbers 1 to 5 label the grid.
- **QR-TEXT-3** — A zone is 5 x 5 modules. Zone `A-1` is the top left. The
  letter names the row of zones from A to E, and the number names the column of
  zones from 1 to 5. The names are the names that SeedSigner shows.
- **QR-TEXT-4** — After the grid view, the program prints the 25 zones in the
  order `A-1` to `A-5`, then B to E. A zone view holds the zone name, the 5
  rows, and the count of dark modules in the zone.
- **QR-TEXT-5** — After each zone view, the program reads one line from standard
  input before the next zone. At the end of the input, it prints the remaining
  zones without a pause.

The tests of this unit live in [TEST-QR](testing.md#test-qr).

<a id="qr-pack"></a>

## The packed release

- **QR-PACK-1** — `scripts/pack` writes `build/fuguseed-qr`: one executable file
  with the program of QR-PROGRAM-1 and the modules of QR-PROGRAM-6 and
  LIST-MODULE-1. `make dist` runs it after `scripts/dist`. The first line of the
  file is `#!/usr/bin/perl`. The air-gapped computer runs the perl of its base
  system, and it installs nothing (D-07).
- **QR-PACK-2** — The packer is a core-only Perl script of this repository. It
  packs the listed modules only: no Fugu module, no core module, and no module
  of `fuguseed-words`.
- **QR-PACK-3** — Two packs of one tree are byte-equal. The file holds no
  timestamp and no build path.
- **QR-PACK-4** — `App::FuguSeed` is the lead module of the distribution. PAUSE
  indexes the distribution through its package. The module holds no code, and
  the packed file holds no part of it.

The release of the file lives in [SEC-RELEASE](security.md#sec-release), and its
tests in [TEST-PACK](testing.md#test-pack).

<a id="qr-manual"></a>

## The manual

- **QR-MANUAL-1** — `man/fuguseed-qr/fuguseed-qr.1` documents the program, the
  input, the exit codes, and the digest check of SEC-RELEASE-2. It documents the
  two results: the SeedQR and the check word.
- **QR-MANUAL-2** — The manual holds the drawing procedure in ASD-STE100 (D-13).
  The procedure names the air-gapped computer, the printed 25 x 25 template, and
  the marker. It draws one zone at a time and counts the dark modules of each
  zone. It ends with the scan on the device that proves the drawing.
- **QR-MANUAL-3** — The manual states that the SeedQR is the 12 words in another
  form, with the WARNING of D-14. It states that a Compact SeedQR is not the
  output (D-04). It states that a consumer such as FuguPass reads the SeedQR and
  no typed word.
- **QR-MANUAL-4** — The drawing must scan under a camera. The template holds a
  quiet zone of 4 light modules around the code, and a module of 5 mm or more.
  The manual names the printable 25 x 25 template of the SeedQR specification as
  the template, or a grid with the same zones.
