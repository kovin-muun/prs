# Cards JavaCard Style Conventions

Scope: `cards/muuncard-firmware/src/main/java/org/muuncard/{v3,metadata}/`.

Extends `.github/review/sources/java/review-java-style.md`. This file covers what's different for
JavaCard firmware.

Base source: `cards/CLAUDE.md` (Code Style, Cards-specific rules).

## Line Length

Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b),
section "Basic rules".

- 100 characters, same as base Java style. Check the actual column count before accepting a wrap.
  Tool-driven edits have repeatedly wrapped lines that already fit on one line.

## Buffer Operation Formatting

Codebase-derived rule. Validate against call sites in `MuunCardV3.java`.

- `Util.arrayCopyNonAtomic`/`Util.arrayCopy`, when wrapped, group arguments in pairs — source
  buffer with its offset, destination buffer with its offset, then length on its own line:
  ```java
  Util.arrayCopyNonAtomic(
          workBuffer, SC_META_AUTH,
          workBuffer, tbsPos,
          METADATA_AUTH_SIZE
  );
  ```
- `Util.arrayFillNonAtomic`, when it fits, stays on one line:
  `Util.arrayFillNonAtomic(workBuffer, INIT_PAD_COMMIT, SECRET_SIZE, (byte) 0);`. When it doesn't
  fit, one argument per line, matching the base Java style guide's parameter-formatting rule.

## Javadoc for Security-Sensitive Methods

Codebase-derived rule. Validate against the protocol and buffer-layout javadocs in
`cards/muuncard-firmware/src/main/java/org/muuncard/v3/MuunCardV3.java` and the SIO contract in
`cards/muuncard-firmware/src/main/java/org/muuncard/metadata/MetadataAppletInterface.java`.

- Methods touching wire format, crypto, or protocol state must document exact byte layout,
  encoding, algorithm, and size, not just intent.
- `@throws ISOException` must list every status word the method can actually throw.
- A method copying across the SIO boundary must state its buffer must be JCRE-owned.
- Flag `{@inheritDoc}` on a JavaCard framework override that has undocumented applet-specific
  behavior.

## Named Constants for Buffer Offsets

Source: `cards/CLAUDE.md`, sections "workBuffer Layout" and "Cards-specific rules".

- Every offset constant should have its length next to it: `CH_DH = 130; // 32 bytes`.
- Extract a constant for any magic number repeated in more than one place.
- See `review-cards-security.md` for when offset reuse is acceptable and how to document it.

## Unused Code

Source: `cards/CLAUDE.md`, section "Code Style", and `linters/checkstyle/config.xml`.

- Flag unused fields, methods, getters, and imports left over from a rename or refactor.
- Before adding a new helper, check whether an existing one does the same thing (e.g.
  `MuunCardV3#performEphemeralEcdh()`).
- Do not flag code marked with a `TODO` comment or a note about a planned future use.

## Duplicated Classes

Source: `cards/CLAUDE.md`, section "Architecture". Validate the package-local implementations at
`cards/muuncard-firmware/src/main/java/org/muuncard/{applet,v3,metadata}/`.

- `Secp256r1`, `Hmac256`, and `Helpers` are duplicated per package because JavaCard's classloader
  isolates packages (`cards/CLAUDE.md`). Package declarations, APIs, and some legacy behavior differ,
  so the files are not expected to be byte-identical.
- When shared logic or constants change, compare every relevant package-local copy and keep their
  shared semantics aligned. Preserve and document intentional package-specific differences.
- When copying shared logic, carry over applicable javadocs and comments without overwriting
  package-specific documentation.

## Naming Precision

Review heuristic, validated against `MetadataApplet`, `MetadataAppletInterface`, and the
[card client-server protocol](https://app.notion.so/muunwallet/Card-client-server-protocol-v2-e25c8573de2c82a1aa41814e82df0b0e).
Use it for suggestions unless a name contradicts the spec.

- A name should not shadow a nearby method's semantic space. Example: a field named `metadata`
  next to `getMetadata()` reads ambiguously; `metadataApplet` doesn't.
- Interface names should say they're an applet's SIO API: `MetadataAppletInterface`, not
  `MetadataInterface`.
- When renaming to match the protocol spec, check every related name against the spec, not just
  internal consistency.

## Duplicated Logic

Review heuristic. Use it for suggestions unless duplication causes a concrete protocol-parity or
buffer-layout defect covered by another cited rule.

- Flag near-identical code across 2+ challenge/pairing variants even if extraction is deferred.
- Prefer unifying two call sites that pass different buffers/offsets for the same conceptual value
  (e.g. a reason hash that lives in different places depending on the code path).

## What Reviewers Check

- Line wraps match the actual 100-char limit.
- Wrapped `arrayCopyNonAtomic`/`arrayCopy` calls group buffer+offset pairs, length on its own line.
- Security-sensitive methods document byte layout, encoding, algorithm, size.
- `@throws ISOException` lists every status word thrown.
- Every offset constant has a length; repeated magic numbers are named constants.
- No unused fields, methods, getters, or imports, unless marked `TODO` or for future use.
- Shared behavior in duplicated per-package classes stays aligned; intentional differences are
  documented.
- Names don't shadow nearby methods; renames match the protocol spec vocabulary.
- Near-identical logic across challenge/pairing variants is flagged.
