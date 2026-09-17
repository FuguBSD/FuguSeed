# 003 — The packed release of fuguseed-qr

## Status

Proposed. It waits on plan 002 for the modules that the packer lists. Plan 004
waits on it for TEST-PACK-1 and TEST-PACK-2.

Implements: QR-PACK, SEC-RELEASE. Implements: TEST-PACK without TEST-PACK-3.

TEST-PACK-3 binds the modules of `fuguseed-words`, so plan 004 lands it.

## Purpose

One file crosses to the air-gapped computer, with one digest and no install step
(D-07). This plan lands `scripts/pack`, which writes `build/fuguseed-qr` from
the modules of this repository. It also lands the tests that run the packed file
on core Perl alone.

The scaffold expects the packer. `mk/local.mk` names `scripts/pack` as the
`DIST` command of `make dist`, and `release.yml` passes `assets: fuguseed-qr` to
the shared release workflow of Tooling. This plan fills the two slots and
changes neither file.

## Constraints that shape the design

**The packer packs the tarball.** `scripts/pack` takes the `--version` and
`--out` options of `scripts/dist`. It runs `scripts/dist` with the same values,
then reads the modules from the tarball that the build writes. It extracts the
tarball into a temporary directory under `build/`, packs from that directory,
and removes the directory. The tarball holds the modules with the `$VERSION` of
the tag, so the packed file names its version. Two packs of one tree and one
version are byte-equal (QR-PACK-3).

**The module list is fixed.** The packer holds the six names of QR-PROGRAM-6 and
LIST-MODULE-1, in dependency order: List, Mnemonic, Codewords, Matrix, Text, QR.
It packs no other module (QR-PACK-2). Before each module it writes a `BEGIN`
block that marks the module as loaded in `%INC`, then the module source. The
program body comes last, under `package main`.

**The packer is core Perl.** It is a bootstrap script of this repository: core
modules only, and v5.34, like `scripts/deps`.

**The shebang is the base perl.** The packed file starts with `#!/usr/bin/perl`.
The air-gapped computer runs its base perl, and D-07 allows no install step
there.

**The release needs no new wiring.** The shared `perl-release` workflow uploads
the asset that `release.yml` names and lists it in the signed `SHA256` manifest
(SEC-RELEASE-1). The manual of plan 002 holds the digest check step
(SEC-RELEASE-2).

## Files

| File                | Change                                              |
| ------------------- | --------------------------------------------------- |
| `scripts/pack`      | The packer                                          |
| `t/fuguseed/pack.t` | The tests below                                     |
| `spec/STATUS.md`    | QR-PACK and SEC-RELEASE `done`, TEST-PACK `partial` |

## Tests

`t/fuguseed/pack.t` packs into a temporary directory with the version `0.0.0`
and holds:

- The packed file runs with an `@INC` of the archlib and the privlib of the
  running perl alone. Test vector 4 is the standard input. Its output equals the
  fixture of plan 002 (TEST-PACK-1).
- The same run passes on `/usr/bin/perl` when that perl exists (TEST-PACK-1).
- Every `use` and `require` line of the packed file names a pragma, a module of
  the packed set, or `Digest::SHA`. No line names a `Fugu::` module
  (TEST-PACK-2, SEC-RELEASE-3).
- The packed file holds no `open`, `opendir`, `system`, `exec`, `fork`,
  backtick, `qx`, or `%ENV`, like the sources in plan 002.
- Two packs of the tree are byte-equal, and the file holds no build path
  (QR-PACK-3).

## Acceptance

- `make check` passes, and `make dist` writes `build/fuguseed-qr` beside the
  tarball.
- QR-PACK and SEC-RELEASE read `done`. TEST-PACK reads `partial` with
  TEST-PACK-3 as the absent part.
- The first release after this change publishes `fuguseed-qr` beside the
  tarballs, and the signed manifest names it. The operator dispatches that
  release.
- The change deletes this plan.

## What this plan does not do

It changes no synced file and asks nothing of Tooling. It packs no module of
`fuguseed-words`.
