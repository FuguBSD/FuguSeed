# The word list

Both programs read the official English word list of BIP39. This document
specifies the list, its two shipped copies, the module that serves it, and the
vocabulary rule of every artifact (D-03, D-10).

<a id="list-source"></a>

## The source list

- **LIST-SOURCE-1** — The list is the file `english.txt` of the BIP39
  specification, unchanged. Its SHA-256 is
  `2f5eed53a4727b4bf8880d8f3f199efc90e58503646d9ff8eff3a2ed3b24dbda`.
- **LIST-SOURCE-2** — The list holds 2048 lines. Each line is one word of 3 to 8
  lower-case ASCII letters, with one line feed after it and no other byte.
- **LIST-SOURCE-3** — The words are unique and sorted. The first four letters of
  each word are unique across the list.
- **LIST-SOURCE-4** — The index of a word is its 0-based line number. A program
  must never derive a word from another source than the list.

<a id="list-share"></a>

## The share file

- **LIST-SHARE-1** — The repository ships the list as
  `share/fuguseed/english.txt`, byte for byte equal to the source list.
- **LIST-SHARE-2** — `fuguseed-words` must resolve the file through
  `Fugu::File->share_path`, in a checkout and in an installed distribution.
- **LIST-SHARE-3** — A program that reads a list file must compute its SHA-256
  and must refuse a list with another digest than LIST-SOURCE-1.

<a id="list-module"></a>

## The list module

- **LIST-MODULE-1** — `App::FuguSeed::List` holds the 2048 words as data in the
  module file. The words sit one per line, so a person can diff them against the
  share file. It holds the pinned SHA-256 of LIST-SOURCE-1 as one constant.
- **LIST-MODULE-2** — The module must run on core Perl v5.34 with no dependency,
  because `fuguseed-qr` packs it (D-07).
- **LIST-MODULE-3** — The module must give the word of an index, the index of a
  word, and the list as an array. An unknown word gives `undef`.
- **LIST-MODULE-4** — One test must compute the SHA-256 of the embedded words
  and of the share file. Both must equal the constant of LIST-MODULE-1.
- **LIST-MODULE-5** — One test must prove LIST-SOURCE-2 and LIST-SOURCE-3 on the
  embedded words.

<a id="list-vocabulary"></a>

## The vocabulary

- **LIST-VOCABULARY-1** — Every artifact names the standards: BIP39 for the
  words, SeedQR for the code. No tracked file that this repository owns holds
  the banned stem `bitcoin` or the banned stem `crypto`, in any letter case
  (D-03). Two exceptions exist: the sentence of this rule that names them, and a
  file that a pack of FuguBSD/Tooling owns.
- **LIST-VOCABULARY-2** — A test must read the banned stems from this document
  and must scan every tracked file for them.
- **LIST-VOCABULARY-3** — The artifacts call the machine that accepts the 12
  words "the device". They call the three dice YELLOW, BLUE, and RED. They use
  "dice" for one die and for several.
