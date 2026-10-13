# Cards Security & Cryptography Conventions

Scope: crypto correctness and protocol security, applying to both the V3 and metadata JavaCard
applets under `cards/muuncard-firmware` and the Go code that must match them: the ceremony client
and the ceremony half of the mock card in `cards/vendor-cli/`, shared by both CLIs, and the pairing
and challenge client and the mock's pairing half in `cards/cards-cli/internal/muuncardv3/`. For
JCOP platform quirks specific to JavaCard (SIO, transactions, workBuffer layout), see
`review-cards-hardware.md` instead.

Base source: `cards/CLAUDE.md` (V3 Protocol, Cards-specific rules).

## Constant-Time Operations

Source: `cards/CLAUDE.md`, section "Cards-specific rules". Validate against
`cards/muuncard-firmware/src/main/java/org/muuncard/v3/Helpers.java` and `MuunCardV3.verifyMac`.

- MAC comparisons, secret selection, and slot lookups must be constant-time. No early return based
  on a secret byte.
- Reuse an existing constant-time compare helper instead of writing a new comparison inline.
  Example: `constantTimeCompare32` in `MuunCardV3.java`.

## EC Public Key Validation

Codebase-derived security rule. Validate against `MuunCardV3.validateEcPublicKey` and its callers.

- Any caller-supplied EC public key must be checked for: uncompressed format, not the point at
  infinity, and membership on secp256r1. See `validateEcPublicKey` in `MuunCardV3.java`.
- Validate centrally, not per caller. Flag validation delegated to callers in upgradeable firmware.
- A method returning a fixed-size crypto output (e.g. a 32-byte ECDH result) should assert the
  returned length instead of trusting it.

## Replay Counters and MAC Verification

Source: `cards/CLAUDE.md`, section "V3 Protocol". Validate against
`MuunCardV3.verifyChallengeAndRespond`, `MuunCardV3.verifyMac`, and the corresponding Go mock.

- Counter checks must reject `receivedCounter <= lastCount`, not just `<`. Test the exact-match
  boundary.
- Counter wraparound (0xFFFF to 0x0000) must be a deliberate, tested decision if the commit message
  claims it.
- Challenge MAC verification tries `secret_next` first, then `conf_secret` if needed. Each attempt
  uses the same full-length constant-time comparison, and a `secret_next` match promotes it to
  `conf_secret`.
- Preserve both the value and placement of each HMAC domain. Pairing and ceremony derivations use
  `pairing-secret` and `vendor-key-{i}` (the key index in decimal ASCII) as HMAC keys. Protocol
  MAC and ratchet inputs use `pairing-response`, `challenge-request`, `challenge-response`, and
  `challenge-ratchet` as prefixes. A missing, moved, or mismatched domain is a forgery or parity risk.

## Cross-Client Crypto Parity

Sources: `cards/CLAUDE.md`, sections "Architecture" and "Cards-specific rules"; strict certificate
parsing is validated against `cards/vendor-cli/muuncardv3/cert.go` and its tests.

- `ComputeHMACSHA256` in `cards/vendor-cli/muuncardv3/main.go` hand-rolls the RFC 2104 ipad/opad
  construction (over `crypto/sha256`) to match
  `cards/muuncard-firmware/src/main/java/org/muuncard/v3/Hmac256.java` byte-for-byte. A change to
  either file without verifying the other is a correctness bug, even if it looks like a pure
  refactor.
- Go ECDH must use `crypto/ecdh`, not `crypto/elliptic`.
- A certificate/CBOR parser must be at least as strict as the reference it replaces. A more lenient
  decoder (accepts duplicate keys, unknown fields, indefinite-length CBOR) weakens what
  `--provider-pub` verification accepts. See `cards/vendor-cli/muuncardv3/cert.go`.

## Provisioning and Development Keys

Sources: `cards/muuncard-firmware/INSTALL_GUIDE.md` and
`cards/cards-cli/internal/relay/PROTOCOL.md`. Validate key fixtures under `cards/muun-v3-keys/`
and CAP signing against `cards/cards-cli/internal/dap/`, `cards/muuncard-firmware/sign_cap.py` and
the matching LFDB hash in `cards/vendor-cli/gp/`, which the card's DAP verification consumes.

- Added or replaced tracked private keys must be explicitly development-only and must not be used
  by production provisioning.
- A CAP signing change must preserve the exact payload and hash algorithm expected by the loader
  and DAP verification path.

## What Reviewers Check

- Every MAC/secret comparison is full-length and constant-time.
- Every externally supplied EC public key is validated for format, infinity, and curve membership.
- Counter checks reject `<=`; wraparound is deliberate and tested.
- HMAC domain values and their key/input placement match across firmware and Go.
- Go and Java HMAC/ECDH stay byte-compatible across the change.
- A certificate/CBOR parser is at least as strict as what it replaces.
- Tracked key changes remain development-only; CAP signing matches loader verification.
