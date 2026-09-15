# fuguseed-words

`fuguseed-words` builds the printed word sheet, checks a built sheet, and holds
the offline procedure in its manuals. It sees no seed word (D-01,
[SEC-TRUST](security.md#sec-trust)). This document specifies the program, the
two verbs, the sheet, and the manuals.

<a id="words-program"></a>

## The program

- **WORDS-PROGRAM-1** — The program is `bin/fuguseed-words`. It holds no logic:
  it calls `App::FuguSeed::Words->run(@ARGV)` and exits with the result.
- **WORDS-PROGRAM-2** — `App::FuguSeed::Words` dispatches through `Fugu::CLI`
  (D-06). The verbs are `build` and `check`. The exit codes come from Fugu
  LIB-CLI: 0 for success, 1 for a failure, and 2 for a usage error.
- **WORDS-PROGRAM-3** — `fuguseed-words --help` and
  `fuguseed-words <verb> --help` must print the usage to standard output and
  exit 0. A command line without a verb is a usage error.
- **WORDS-PROGRAM-4** — Standard output carries the result of a verb only. Every
  diagnostic goes to standard error through `Fugu::Log` in stderr mode.
- **WORDS-PROGRAM-5** — The source floor is Perl v5.36. The modules that the
  program loads can use every core module and every `Fugu::` module.

The trust rule of the program lives in [SEC-TRUST](security.md#sec-trust), and
its test in [TEST-PACK](testing.md#test-pack).

<a id="words-build"></a>

## The build verb

- **WORDS-BUILD-1** — `fuguseed-words build <list>` reads the word list file
  `<list>` and writes the sheet as HTML to standard output. The list argument is
  required, and LIST-SHARE-3 governs its digest.
- **WORDS-BUILD-2** — The verb reads two share files: the template
  `share/fuguseed/sheet.html` and the style sheet `share/fuguseed/sheet.css`. It
  inlines the style sheet into one `<style>` element, so the result is one
  standalone file.
- **WORDS-BUILD-3** — The sheet is HTML5 with no `class`, `id`, `style`, `dir`,
  or `hidden` attribute. It holds no script, no comment, and no entity. Every
  byte is printable ASCII, a tab, or a line feed. The style sheet selects by
  element and by structure only.
- **WORDS-BUILD-4** — The sheet holds two sides for A4 paper. Side 1 holds the
  YELLOW blocks 1 to 4, and side 2 holds the YELLOW blocks 5 to 8. Each side is
  one `<section>`, and the style sheet breaks the page between them.
- **WORDS-BUILD-5** — Each block is one `<table>`. Its `<caption>` reads
  `YELLOW <n>`. The header row holds `RED 1` to `RED 16` as column headers. Each
  of the 16 body rows starts with the row header `BLUE <n>` and holds 16 cells.
- **WORDS-BUILD-6** — The cell in block Y, row B, and column R holds the word of
  index `(Y-1)*256 + (B-1)*16 + (R-1)` (D-05), complete and unchanged.
- **WORDS-BUILD-7** — Each side holds a legend that names the dice and their
  roles. Each side holds a footer that names the side, the standard, the SHA-256
  of the list, and the build date. A `--date YYYY-MM-DD` option sets the date,
  so two builds of one list on one date are byte-equal.
- **WORDS-BUILD-8** — `App::FuguSeed::Sheet` builds the sheet text from the
  list, the template, the style sheet, and the date. It writes no file.

<a id="words-check"></a>

## The check verb

- **WORDS-CHECK-1** — `fuguseed-words check <sheet> <list>` reads a built sheet
  and a word list file, and proves that the sheet is correct for the list. Both
  arguments are required, and LIST-SHARE-3 governs the list.
- **WORDS-CHECK-2** — The verb is silent on success and exits 0. On a failure,
  it prints each defect on one line of standard error and exits 1.
- **WORDS-CHECK-3** — `App::FuguSeed::Check` implements the check without
  `App::FuguSeed::Sheet`, so a defect in the builder cannot hide in the checker.
- **WORDS-CHECK-4** — The check consumes the whole sheet as one strict grammar
  from the first byte to the last (D-09). Any byte that the grammar does not
  expect is a defect, and the message names the byte offset.
- **WORDS-CHECK-5** — The check compares the inlined style sheet with
  `share/fuguseed/sheet.css` byte for byte, and it rejects every attribute and
  every construct that WORDS-BUILD-3 forbids.
- **WORDS-CHECK-6** — The check compares each caption, each column header, each
  row header, and each of the 2048 cells with its expected text, by position. It
  proves that each word appears once, and that the two footers name the digest
  of the list.

The tests of the check live in [TEST-SHEET](testing.md#test-sheet).

<a id="words-manual"></a>

## The manuals

- **WORDS-MANUAL-1** — `man/fuguseed-words/fuguseed-words.1` documents the
  program, the two verbs, the exit codes, and the print instructions: A4, both
  sides, 100 percent scale, in color.
- **WORDS-MANUAL-2** — `man/fuguseed/fuguseed.7` holds the offline procedure in
  ASD-STE100 (D-13). Its sections follow the procedure: the equipment and the
  names, the steps before the start, and how to find one word. Then words 1 to
  11, word 12, and the steps after the procedure.
- **WORDS-MANUAL-3** — The procedure states that the dice give words 1 to 11,
  and that word 12 is the check word. The device finds word 12 among the 16
  words of the BLUE row that YELLOW and BLUE select (D-02).
- **WORDS-MANUAL-4** — The procedure holds the WARNING of D-14 and the note on
  the faces 6 and 9. It holds the rule against a BIP39 passphrase, and the rule
  to select the complete word on the device. It requires the comparison of the
  device with the paper before any use, and a second copy.
- **WORDS-MANUAL-5** — The procedure ends with a pointer to `fuguseed-qr(1)` for
  the SeedQR, the form of the words that a consumer such as FuguPass reads. It
  names no software for the roll of the dice.
- **WORDS-MANUAL-6** — `make man` renders each page with `mandoc -Tascii`
  ([TEST-MANUAL](testing.md#test-manual)).
