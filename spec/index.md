# FuguSeed specification

FuguSeed helps one person make BIP39 seed words with three dice, on paper, and
turn them into a SeedQR. Two programs exist. `fuguseed-words` builds a printed
word sheet from the official English word list, checks a built sheet, and holds
the offline procedure in its manual. It sees no seed word. `fuguseed-qr` reads
12 seed words and prints a Standard SeedQR as text, zone by zone, so a person
can draw it on paper. It sees the words, so it runs on an air-gapped computer
only. No program generates a seed word. The dice give the entropy, the paper
holds the words, and a device that accepts BIP39 words finds the check word.

This document is the entry point of the specification. It holds the plan
contract, the ID conventions, and the document tables.

## Plan contract

- Read [DECISIONS.md](DECISIONS.md) before you make a plan.
- A plan must not go against a decision. To go against a decision, propose a
  change to [DECISIONS.md](DECISIONS.md) and get human approval first.
- A plan must cite each unit that it implements and that is not `done`, for
  example `Implements: WORDS-BUILD`.
- A plan can exclude a rule from a unit under `Implements:` with `without`, for
  example `Implements: WORDS-BUILD without WORDS-BUILD-6`.
- A plan must cite each unit that it touches but neither implements nor extends,
  for example `Defers: QR-PACK`.
- A plan must cite each `done` unit that it extends, for example
  `Extends: OVW-VOCABULARY`.
- The change that implements a unit, or a part of one, must set the unit state
  in [STATUS.md](STATUS.md) in the same change.

<a id="conventions"></a>

## Conventions

The ID overlay lives in [spec/CLAUDE.md](CLAUDE.md): the unit anchors, the rule
shape, the append-only numbers, the retire procedure, and the citation forms.

## Specification documents

Each document specifies one area of work. The code of a document prefixes the
IDs of its units.

| Code  | Document                   | Area                                                   |
| ----- | -------------------------- | ------------------------------------------------------ |
| OVW   | [overview.md](overview.md) | The purpose, the scope, the vocabulary, and the limits |
| LIST  | [list.md](list.md)         | The word list, its copies, and the list module         |
| WORDS | [words.md](words.md)       | `fuguseed-words`: the sheet, the check, the manual     |
| QR    | [qr.md](qr.md)             | `fuguseed-qr`: the words, the code, the pack           |
| SEC   | [security.md](security.md) | The trust levels, the channels, and the release        |
| TEST  | [testing.md](testing.md)   | The rules that bind the tests                          |

## Governance documents

These documents carry no units.

| Document                     | Role                                                  |
| ---------------------------- | ----------------------------------------------------- |
| [DECISIONS.md](DECISIONS.md) | The decisions. A plan must not go against a decision. |
| [ROADMAP.md](ROADMAP.md)     | The schedule of the work.                             |
| [STATUS.md](STATUS.md)       | The implementation register.                          |
