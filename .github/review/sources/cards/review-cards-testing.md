# Cards Testing Conventions

Scope: `cards/muuncard-firmware/src/test/java/org/muuncard/{v3,metadata}/`,
`cards/cards-cli/internal/muuncardv3/*_test.go`, `cards/cards-cli/internal/relay/*_test.go`,
`cards/cards-cli/internal/dmtoken/*_test.go`, `cards/cards-cli/internal/dap/*_test.go`, and
`cards/vendor-cli/**/*_test.go`.

Base source: `cards/CLAUDE.md` (E2E Testing on Hardware, Commit Discipline). Cards follows the
same reasons Muun writes tests generally (Notion "Our practices" and "On testing": confidence in
correctness, fewer regressions during refactors, and documentation of intended behavior) — cards
just has no service or database, so it has no Unit/Integration/E2E split to extend. The tiers
below are the hardware-shaped version of the same idea.

## Three Testing Tiers

Source: `cards/CLAUDE.md`, sections "Build and Test", "E2E Testing on Hardware", and "Commit
Discipline".

- Go unit tests, JCardSim, and hardware E2E each cover something the others can't. Hardware E2E is
  the only tier that exercises real APDU buffer size, the SIO firewall, and crypto-engine behavior
  around SIO calls.
- A protocol or applet behavior change that updates only one tier is incomplete
  (`cards/CLAUDE.md`'s atomicity rule).

## No Silent JCardSim Skips

Source: `cards/CLAUDE.md`, section "Cards-specific rules". Validate against assumption handling in
`cards/muuncard-firmware/src/test/java/org/muuncard/v3/MuunCardV3Test.java`.

- A test that catches an exception and returns on JCardSim reports as passing while verifying
  nothing.
- Use `Assume` so JUnit reports the case as skipped, with a message stating why and where real
  coverage exists:
  ```java
  Assume.assumeTrue(
      "Skipped: JCardSim APDU buffer lifecycle differs from JCOP. " +
      "Equivalent coverage exists in muuncardv3 Go tests, verified on hardware.",
      result != null
  );
  ```
- `cards/CLAUDE.md`: "if a test skips on JCardSim, add a comment explaining why and that it's
  verified on hardware." A skip with no comment, or one that silently passes, is a defect.

## Boundary and Adversarial Coverage

Codebase-derived security-testing rule. Validate against `MuunCardV3Test.java`,
`cards/vendor-cli/muuncardv3/mockcard_test.go`, `cards/cards-cli/internal/muuncardv3/mockcard_test.go`,
and certificate parser tests when those paths change.

- Security-critical code needs tampered-input tests, not just happy path. Categories that
  generalize to any protocol change:
  - flip a bit in a MAC/signature field and assert rejection
  - exact-match counter boundary (must reject, not just strictly-lower), max counter value
  - an EC point that decodes but isn't on the curve
  - a flag byte that's neither 0 nor 1 where the code does `if (x != 0)`
  - state-machine edges: starting streaming twice, an unrelated command mid-stream
- Test cross-flow interaction, not just methods in isolation from a fresh install. Example: PAIR
  after STORE_CERTIFICATE, the deployed configuration for every provisioned card.
- Missing coverage for a security-critical path is a BLOCKER, not a follow-up.

## Test Naming

Review heuristic. Use it for suggestions unless the mismatch hides missing coverage of a property
required by `cards/CLAUDE.md`.

- A test name claiming a crypto property should match what the assertions check. Example: a test
  named for "forward secrecy" that only checks a secret value changed. The testable property in a
  ratchet protocol is post-compromise security: after rotation, the old secret must stop working.
  Name and assert that directly.

## Test Code Style

Source: Notion
["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b).

- Apply the same Java formatting rules to test code as production code.

## What Reviewers Check

- A protocol/applet behavior change updates all three tiers.
- Every JCardSim skip reports as skipped (via `Assume`), never a silent pass, with a comment
  stating why and where real coverage exists.
- Security-critical verification code has at least one tampered-input test.
- Counter/length boundary conditions are tested explicitly.
- A method whose behavior depends on prior applet state is tested in that sequence, not only from
  a fresh install.
- Test names match the property being verified.
- Test code follows the same formatting rules as production code.
