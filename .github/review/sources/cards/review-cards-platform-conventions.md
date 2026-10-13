# Cards Go Platform Conventions

Scope: V3-related changes under `cards/cards-cli/` (`main.go`, `go.mod`, `go.sum`,
`internal/legacy/`, `internal/muuncardv3/`, `internal/dap/`, `internal/dmtoken/`,
`internal/relay/`) and under `cards/vendor-cli/`.

This file does not restate base Go style (line length, error-message casing, boolean-vs-enum,
etc.) — apply `.github/review/sources/go/review-go-style.md` for that; cards does not deviate from
it. This file covers what's specific to cards: the module boundary between the two CLIs,
mock/firmware parity, and what may live in the vendor distribution. For crypto correctness
(HMAC/ECDH parity with the JavaCard side), see `review-cards-security.md`.

Note: don't skip a finding because a linter "should" catch it; report real violations even when
`golangci-lint` would also flag them.

Base source: `cards/CLAUDE.md` (Architecture, Cards-specific rules).

## One Copy, One Direction

Codebase-derived rule. Validate against `cards/cards-cli/go.mod`'s require and replace of
`github.com/muun/muuncard-vendor`, and the imports in `cards/cards-cli/main.go` and its
`relay/` package.

- There is one copy of the ceremony client, the GlobalPlatform loader and the APDU transport: the
  `muuncardv3`, `gp` and `javacard` packages of the vendor module. The internal CLI imports them;
  it keeps no copies of its own.
- The shared commands have one implementation too, in `cards/vendor-cli/commands/`: `initialize`,
  `configure-cert`, `metadata`. The internal CLI mounts those constructors under `muunv3` rather
  than defining its own.
- The user-side protocol is the internal CLI's alone: the pairing and challenge client and the mock
  card live in `cards/cards-cli/internal/muuncardv3/`, the DAP signer in
  `cards/cards-cli/internal/dap/`, and their commands (`pair`, `challenge`, `sign-cap`, `upgrade`)
  in `cards/cards-cli/main.go`. They build on the vendor packages, never the other way round.
- `cards/cards-cli/internal/legacy/` is not a second transport: it holds the instruction bytes,
  status words and helpers of the deprecated and third-party clients. `javacard` is the vendor
  transport everywhere, in both modules.
- **The dependency only ever points from `cards-cli` to `vendor-cli`.** The internal CLI's
  packages sit under `cards-cli/internal/`, so Go rejects the import outright — "use of internal
  package ... not allowed" — instead of leaving it to review. The vendor distribution has to build
  on its own, without the rest of this repo.
- Those vendor packages are exported rather than `internal/` **because** the internal CLI imports
  them. What the vendor module exports beyond its own commands is exactly what the internal CLI's
  pairing client and mock need (`ComputeHMACSHA256`, `ParseMetadata`, `ValidateECPublicKey`,
  `ScalarMultG`, `VerifyCertAgainstAttestationKey`); flag a new export with no internal caller.
- A behavioral change to a shared command is a change to both CLIs at once. What still differs
  between them is only what the internal CLI keeps for itself, and that difference belongs in
  `cards/`, never in the vendor module.

## Mock/Firmware Parity

Source: `cards/CLAUDE.md`, sections "Architecture" and "Commit Discipline". Validate against
`cards/vendor-cli/muuncardv3/mockcard.go` (ceremony), `cards/cards-cli/internal/muuncardv3/mockcard.go`
(pairing and challenges) and the matching JavaCard applet methods.

- The mockcard must match the firmware byte-for-byte (`cards/CLAUDE.md`). A firmware protocol
  change needs the matching mockcard update in the same commit.
- Watch for a mockcard field keeping an old name after the firmware and spec rename the underlying
  field.

## Unused Code

Codebase-derived rule. This matters most in code we plan to open source, such as
`cards/vendor-cli/` and the firmware.

- Flag unused functions, methods, variables, and imports left over from a rename or refactor.
- Do not flag code marked with a `TODO` comment or a note about a planned future use.

## What May Live In The Vendor Distribution

Codebase-derived rule. Validate module boundaries in `cards/vendor-cli/go.mod` and the imports
under `cards/vendor-cli/`. Treat dead-code and unused-export checks as review heuristics unless
they also violate the base Go style guide.

- The vendor module holds only what the vendor CLI itself uses. Something the internal CLI needs
  and vendors do not gets built in `cards/cards-cli/`, on top of the vendor packages — its
  `dmtoken/`, `dap/` and `muuncardv3/` packages are the worked examples: Delegated Management, DAP
  signing, and the pairing and challenge protocol were dropped from the vendor distribution, so
  they live there instead.
- The exception is a helper that has to stay in lockstep with vendor code to be correct.
  `gp.LoadBlockCount` has no vendor caller but mirrors `gp.Load`'s block framing, so it lives
  beside it; a copy in the relay would drift. Expect that argument to be made explicitly.
- Flag dead or unrelated code in the vendor module, and unused exported crypto in particular: it
  ships to external vendors untested. A capability the product deliberately does not offer does
  not belong there at all — local certificate signing was removed for exactly this reason.

## What Reviewers Check

- Nothing under `cards/vendor-cli/` imports `github.com/muun/cards-cli/...`.
- A shared behavior lives in one place, not re-implemented on the `cards` side.
- A firmware protocol change ships with the matching mockcard update, same commit.
- No unused functions, methods, variables, or imports, unless marked `TODO` or for future use.
- The vendor module carries no unrelated code and no unused exported crypto.
