# Cards JavaCard Hardware Conventions

Scope: `cards/muuncard-firmware` (V3 and metadata JavaCard applets). JavaCard-only: these are JCOP
platform quirks, not portable crypto/security rules. Skip this file for Go-only changes. For
crypto correctness that also applies to the Go side (constant-time comparisons, EC pubkey
validation, replay counters, cross-client parity, key provisioning), see
`review-cards-security.md`.

Base source: `cards/CLAUDE.md`, section "JCOP Hardware Constraints".

## workBuffer Offset Reuse

Source: `cards/CLAUDE.md`, sections "workBuffer Layout" and "JCOP Hardware Constraints". The
class-level memory map in `MuunCardV3.java` is authoritative for concrete offsets.

- Every offset constant used for more than one purpose needs its own name and a documented length
  for each use.
- Check every workBuffer write against the worst-case length of its data, not the typical-case
  length. Example failure pattern: a write to a lower offset (e.g. metadata) that runs past the
  start of a higher offset (e.g. a MAC) once its data grows (e.g. after a certificate is stored).
  Verify there is a test that exercises the sequence that produces the worst-case length.
- Prefer one atomic `Util.arrayCopy` over staging through the buffer twice when the source is
  already in a JCRE-owned buffer.

## No Crypto Inside SIO Calls

Source: `cards/CLAUDE.md`, section "JCOP Hardware Constraints", and the contract javadoc in
`MetadataAppletInterface.java`.

- The crypto engine (SHA-256, ECDH, ECDSA, `genKeyPair`) does not work inside a `Shareable`/SIO
  (Shareable Interface Object) call on JCOP hardware. `MetadataApplet` SIO methods must be pure
  data operations. JCardSim does not catch this.
- An SIO call can disturb the crypto engine's state, so never make one between a key's setup
  (`setS`, `init`) and the operation that uses it. SIO, then crypto, then SIO again works on JCOP 4
  when each crypto operation sets up its key after the last SIO call.

## Transactions

Source: `cards/CLAUDE.md`, section "JCOP Hardware Constraints".

- `genKeyPair()` inside a transaction can exceed the JCOP commit buffer. Keep transactions small;
  run crypto outside them.
- No nested transactions. An SIO method called from inside the caller's transaction must not start
  its own.

## What Reviewers Check

- Every reused workBuffer offset has a name, a length, and both uses documented.
- Every workBuffer write is checked against the worst-case data length.
- No crypto call is reachable from a method invoked through SIO.
- `genKeyPair()` never runs inside a transaction; no nested transactions.
