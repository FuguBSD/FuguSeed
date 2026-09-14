# Implementation register

This register is the one record of implementation state. One row exists for each
unit of the specification. A unit is one design element of one specification
document. The [conventions](index.md#conventions) define the unit IDs. Each row
describes the current state only. A row must not carry a plan name or a
reference to an earlier state. A note can carry the date of a recorded fact.

## States

| State   | Meaning                                                              |
| ------- | -------------------------------------------------------------------- |
| open    | No code implements the unit.                                         |
| partial | Code implements a part of the unit. The note names each absent part. |
| done    | Code implements the full unit. The note links the code or the tests. |
| n-a     | No code can implement the unit. It exists for citation only.         |

The "Done by" column names a phase of the [roadmap](ROADMAP.md), or "—" when no
phase applies.

## Units

| Unit                                         | State | Done by | Note                                                                           |
| -------------------------------------------- | ----- | ------- | ------------------------------------------------------------------------------ |
| [OVW-PURPOSE](overview.md#ovw-purpose)       | n-a   | —       | Citation only.                                                                 |
| [OVW-SCOPE](overview.md#ovw-scope)           | n-a   | —       | Citation only.                                                                 |
| [OVW-VOCABULARY](overview.md#ovw-vocabulary) | done  | —       | [vocabulary.t](../t/fuguseed/vocabulary.t) reads the words and scans the tree. |
| [OVW-RISKS](overview.md#ovw-risks)           | n-a   | —       | Citation only.                                                                 |
| [LIST-SOURCE](list.md#list-source)           | n-a   | —       | The properties of an external file. TEST-LIST-2 proves them.                   |
| [LIST-SHARE](list.md#list-share)             | open  | —       | —                                                                              |
| [LIST-MODULE](list.md#list-module)           | open  | —       | —                                                                              |
| [WORDS-PROGRAM](words.md#words-program)      | open  | —       | —                                                                              |
| [WORDS-BUILD](words.md#words-build)          | open  | —       | —                                                                              |
| [WORDS-CHECK](words.md#words-check)          | open  | —       | —                                                                              |
| [WORDS-MANUAL](words.md#words-manual)        | open  | —       | —                                                                              |
| [QR-PROGRAM](qr.md#qr-program)               | open  | —       | —                                                                              |
| [QR-MNEMONIC](qr.md#qr-mnemonic)             | open  | —       | —                                                                              |
| [QR-CODEWORDS](qr.md#qr-codewords)           | open  | —       | —                                                                              |
| [QR-MATRIX](qr.md#qr-matrix)                 | open  | —       | —                                                                              |
| [QR-TEXT](qr.md#qr-text)                     | open  | —       | —                                                                              |
| [QR-PACK](qr.md#qr-pack)                     | open  | —       | —                                                                              |
| [QR-MANUAL](qr.md#qr-manual)                 | open  | —       | —                                                                              |
| [SEC-TRUST](security.md#sec-trust)           | open  | —       | —                                                                              |
| [SEC-CHANNELS](security.md#sec-channels)     | open  | —       | —                                                                              |
| [SEC-RELEASE](security.md#sec-release)       | open  | —       | —                                                                              |
| [TEST-LIST](testing.md#test-list)            | open  | —       | —                                                                              |
| [TEST-SHEET](testing.md#test-sheet)          | open  | —       | —                                                                              |
| [TEST-QR](testing.md#test-qr)                | open  | —       | —                                                                              |
| [TEST-PACK](testing.md#test-pack)            | open  | —       | —                                                                              |
| [TEST-MANUAL](testing.md#test-manual)        | open  | —       | —                                                                              |

## Update protocol

1. The change that implements a unit, or a part of one, sets the unit state in
   this register in the same change.
2. A `partial` note names each absent rule or part. For each absent part, the
   note names the unit that the part needs.
3. A `done` note holds at least one relative link to code or to tests.
4. A change to the text of a `partial` or `done` unit updates the row of that
   unit in the same change. The CI drift check enforces this rule.
5. The human merge review compares the register diff with the code diff.

## Code roots

The drift gate maps each document to the code that implements it.

| Document    | Roots                                                                           |
| ----------- | ------------------------------------------------------------------------------- |
| overview.md | `t/fuguseed/vocabulary.t`                                                       |
| list.md     | `lib/App/FuguSeed/List.pm`, `share`, `t/fuguseed/list.t`                        |
| words.md    | `lib`, `bin/fuguseed-words`, `share`, `man`, `mk`, `t`                          |
| qr.md       | `lib`, `bin/fuguseed-qr`, `scripts/pack`, `mk`, `.github/workflows`, `man`, `t` |
| security.md | `lib`, `bin`, `t`                                                               |
| testing.md  | `t`                                                                             |
