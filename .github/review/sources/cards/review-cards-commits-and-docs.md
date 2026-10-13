# Cards Commit & Documentation Conventions

Scope: reviewability of any `cards/`-touching change.

The canonical source is `cards/CLAUDE.md`'s Commit Discipline section. Read it in full. This file
adds the documentation-sync rules that go with it.

PR descriptions, review threads, and force-push history are out of scope for this local review.

## Atomic Commit Discipline

Source: `cards/CLAUDE.md`, section "Commit Discipline".

- Every commit must be single-focus, working-state, independently revertible, and describable in
  one sentence (`cards/CLAUDE.md`'s Commit Discipline section).
- A commit doing several unrelated things at once is a BLOCKER, not a NIT.
- A firmware protocol change must move with its mockcard, Go clients, their instruction bytes and
  status words (`vendor-cli/javacard/constants.go` for the ceremony,
  `cards-cli/internal/muuncardv3/constants.go` for pairing and challenges), and tests in one
  commit. Do not ask for a lockstep commit like this to be split further; check that it is one
  purpose, not several.

## Separate Renames From Behavior Changes

Source: `cards/CLAUDE.md`, sections "Commit Discipline" and "V3 Protocol", plus the
[card client-server protocol](https://app.notion.so/muunwallet/Card-client-server-protocol-v2-e25c8573de2c82a1aa41814e82df0b0e).

- A rename and a behavior change belong in separate commits.
- Each rename belongs in its own commit. Flag a commit that renames several unrelated things.
- A rename that changes meaning, not just spelling, must match the protocol spec vocabulary.

## Documentation Sync

Source: `cards/CLAUDE.md`, section "Commit Discipline". Validate against
`cards/muuncard-firmware/README.md`, `cards/muuncard-firmware/INSTALL_GUIDE.md`, and the changed
class-level javadocs.

- Docs must update in the same commit as the behavior they describe.
- Check `cards/CLAUDE.md`, class-level javadoc memory maps, and install/README docs against the new
  code, including: method names after a rename, protocol descriptions (e.g. number of ECDH
  operations), and timing descriptions (e.g. when a counter increments).

## What Reviewers Check

- No single commit mixes more than one logical change.
- Rename-only changes are separated from behavior changes.
- Renames are checked against the protocol spec vocabulary.
- `cards/CLAUDE.md`, javadoc memory maps, and install/README docs match the new behavior.
