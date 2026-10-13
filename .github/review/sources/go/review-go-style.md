# Muun Go Style Conventions

Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558) + PR review patterns.
Relevant quote: "We have two goals in mind when choosing our code style: 1. Readability — Code will be read a lot so we optimize for reading. 2. Consistency — readers should not need to make an effort to understand the structure of the code since it will always be the same."

These rules apply to **all Go code in the repo**. Libwallet adds architectural rules on top — see
`review-libwallet-conventions.md` for changes under `libwallet/`.

Validated against codebase:
- [`fetch_card_offer_action.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/subsystems/marketplace/internal/domain/action/fetch_card_offer_action.go)
- [`errors.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/base/data/securekv/errors.go)
- [`.muun-golangci.yml` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/.muun-golangci.yml)

## Goals
1. Readability — optimize for reading
2. Consistency — readers shouldn't struggle to understand code structure

## Formatting
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Basic rules"

- Line length: 100 characters
- Indentation: tabs, width 4
- No more than one blank line between units of code

## Names
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Names"
Relevant quote: "Use descriptive names for functions, types and variables. Don't abbreviate."

- Descriptive names, no abbreviations. The only accepted variable abbreviations are `ok`, `err`,
  `ctx`, and 1-3 letter receiver names. `i`/`j` only for pure indices with no domain meaning.
- Acronyms stay uppercase in identifiers: `ID`, `RPC`, `TLS`, `JSON`, `UUID` (Go's official
  guideline). Note this is the **opposite** of the Java/Kotlin rule (`Utxo` not `UTXO`) — Go
  follows the standard Go convention.
- Constructors are named `NewXxx` (or `newXxx` if private to the package).
- printf-style functions take an `f` suffix (`Errorf`, `Sprintf`, `CheckNotNilf`) — this is what
  lets `go vet` verify the format string against its arguments.
- Quantities in a basic type carry the unit as a suffix: `amountInSats int`. Prefer a strong named
  type when possible: `type Satoshis int`.
- Avoid boolean parameters — use an explicit enum instead.

## Constants and Enums
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Constants and enums"

- Prefer string-typed enums with named constants so values are human-readable when stored, logged,
  or serialized.
- For integer enums, declare the type once and let `iota` increment from the first constant.

## Files and Packages
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Files and packages"

- One top-level definition per file when it carries meaningful logic. Each significant struct, with
  its methods, gets its own file. Trivially-related helpers/DTOs may share a file.
- A method lives in the same file as the struct it belongs to.
- Composed package names use `_` separators (`incoming_htlc`, `security_card`). This deliberately
  diverges from Go's no-separator convention for readability — `golangci-lint` is configured to
  allow it (see the "underscores in package names" exclusion in `.muun-golangci.yml`).
- A package that defines its own business errors collects them in a per-package `errors.go`.
  Validated against codebase: [`errors.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/base/data/securekv/errors.go)

## Visibility
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Visibility"

- Use the least possible visibility. If a type, function, constant, or field doesn't need to leave
  the package, keep it unexported.
- Common pattern: an error type is exported (so callers can match with `errors.As`), but its
  constructor is unexported (so only the owning package can create instances).

## Interfaces and Structs
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Interfaces and structs"

- Prefer constructors (`NewFoo`) over struct literals for initialization. For domain models this is
  **required**, not just suggested — it avoids partial-initialization footguns and allows
  validation on construction.
- When a struct literal is appropriate, use explicit field names. Avoid positional struct literals
  (the only exception is the single embedded field / newtype pattern).
- Actions, repositories, and clients should be interfaces by default (Go only mocks interfaces).
  Return the interface from the constructor; keep the implementation struct unexported.
  Validated against codebase: [`fetch_card_offer_action.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/subsystems/marketplace/internal/domain/action/fetch_card_offer_action.go)
- Internal types/functions stay concrete and unexported. Test infrastructure and platform
  primitives may return concrete types — the interface rule is for domain abstractions.

## Error Handling
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Error handling"

- Use `github.com/go-errors/errors`, not the stdlib `errors` or `fmt.Errorf` — this guarantees
  stack traces captured at the error site. **Enforced** by `forbidigo` in `.muun-golangci.yml`
  (`fmt.Errorf` and stdlib `errors.New` are forbidden).
- On a `(value, error)` return, the value must be the zero value when an error is returned.
  Otherwise document the decision thoroughly. Avoid returning partially-initialized values.
- Do NOT wrap an error when no significant context is added — the stack trace already carries the
  call chain. `errors.Errorf("functionName: %w", err)` is noise.
- DO wrap at the boundary of an external dependency (those errors lack stack traces). Use `%w` with
  a short, lowercase prefix naming the failing step — no "failed to", no trailing punctuation:
  `return errors.Errorf("send request: %w", err)`.
- Preserve two related errors with multiple `%w`:
  `errors.Errorf("retry failed: %w (original error: %w)", retryErr, originalErr)`.
- Match errors with `errors.Is` / `errors.As`, never `==`.
- Panic (don't return an error) on invariant/precondition violations that cannot be recovered from.
  Panics carry error values with stack traces, not plain strings:
  `panic(errors.Errorf("expected X to be Y, got %v", x))`. In libwallet, use its
  `platform/preconditions` package instead of a native `panic`.
- Introduce a typed error only when handling it is part of the API contract (a real caller needs
  it). Standard shape: an anonymously embedded `error` field in a named struct, created through an
  unexported constructor.
  Validated against codebase: [`errors.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/base/data/securekv/errors.go)
- Destructors (`Close`, `Disconnect`, `Release`) are always called with `defer`, must be nil-safe
  and safe to call twice, and should log rather than return errors.

## Observability / Logging
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Observability"

- Use structured (key-value) logging. Don't interpolate values into the message.
- Messages are one short capitalized sentence in human-readable English; variable data goes in
  fields. Errors are passed as an `"error"` field, never interpolated.
- Log-and-return only when the log site has context the caller can't reconstruct. Otherwise wrap
  and return — don't double-log the same failure on its way up.

## Context
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Context"

- IO functions/methods take `ctx context.Context` as the first parameter. Constructors that perform
  IO also take ctx.
- Pure functions (no IO, no side effects, no logging) do NOT take ctx — adding one "just in case"
  is noise.
- In tests, get the context from `t.Context()`, not `context.Background()`, so it's canceled when
  the test ends.
- Prefer the context-aware variant of any stdlib function (enforced by `noctx`).
- Context value keys are unexported zero-sized struct types: `type ctxKey struct{}`.

## Control Flow
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Control flow"

- Always use braces.
- Multi-statement ifs (`if err := foo(); err != nil { ... }`) are fine when the statements are
  simple, short, and clear. When in doubt, split into two statements.

## Functions
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Functions"

- Named return values are forbidden — they make `return` surprising.
- Go has no generic methods; when you need one, write a free function taking the receiver as the
  first parameter.
- When a signature exceeds the line length, put each parameter on its own line with the closing `)`
  alone on its line. The same applies to call sites.
- Multiple return values beyond a trailing `error` are heavily discouraged — often a sign of a
  missing abstraction or an over-responsible function.

## Imports
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Imports"

- Three blocks separated by a blank line: standard library, third-party, first-party. Enforced by
  `goimports`.
- Short aliases when package names collide or the qualified name is awkward.
- Use `any`, not `interface{}` (also enforced by `modernize`).
- No dot imports.

## Testing
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Testing"

- Use `github.com/stretchr/testify`.
- Mark every test helper with `t.Helper()` (or `s.T().Helper()` in a suite) so failures report the
  call site.
- Helpers that need cleanup use `t.Cleanup(...)` rather than requiring `defer` from the caller.
- Integration tests should use test suites for the harness. When a test file grows large, split it
  by concern with a shared `suite_test.go` base suite.
- All test logs via `t.Log` / `t.Logf`, used sparingly (high-value logs only).
- (Libwallet's suite conventions are in `review-libwallet-conventions.md`.)

## Documentation
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Documentation"

- Use `//` for all comments — Go does not use `/* ... */` for documentation.
- Docstrings on exported types/functions start with the identifier name and use imperative present
  tense ("Compute returns the fee", not "Computes the fee").
- Document intent in the godoc; document implementation detail inside the function body.

## Misc
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Misc"

- Unit separators on literal numbers: `1_123_456`, not `1123456`.
- Chained method calls: one thing per line.
- No unnecessary parentheses unless precedence is non-obvious or you're grouping for emphasis.

## Automatic Enforcement
Source: Notion ["Go style-conventions guide"](https://www.notion.so/209c8573de2c8081a4fbf9c803f91558), section "Automatic Enforcement"; codebase
[`.muun-golangci.yml` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/.muun-golangci.yml)

Many of these conventions are enforced automatically by `golangci-lint` (run via `muun lint`, the
pre-commit hook, and CI) and by `goimports`. Enabled linters include `staticcheck`, `errorlint`,
`errcheck`, `noctx`, `modernize`, `revive`, `govet`, `gosec`, `goconst`, `misspell`, `bodyclose`,
`lll` (100-char), `forbidigo` (forbids stdlib `fmt.Errorf` / `errors.New`), `depguard`, and
libwallet's custom analyzers (`muun_model_constructor`, `muun_errorf_wrap`,
`muun_subsystem_boundary`, `muun_one_struct`, `muun_struct_order`, `muun_presentation_purity`).

A convention being lint-enforced does NOT make it out of scope for review: report a real violation
even when `golangci-lint` would also catch it. The linters' `paths:` exclusions in
`.muun-golangci.yml` only skip vendored, build and generated-mock files; the formatters also skip
`alb-log-forwarder` and `tools`.

### Linter exception syntax

When a specific lint rule must be skipped, annotate the line with `//nolint:` and a brief
justification:
```go
someFuncThatReturnsError() //nolint:errcheck, no possible error handling in this situation                                             
```

## What Reviewers Check
- Descriptive names; correct acronym casing (`ID`/`JSON` uppercase); no stray abbreviations.
- Errors use `go-errors/errors`, wrapped only at external boundaries with a short lowercase `%w`
  prefix; no redundant `functionName:` wrapping; `(zero, err)` on failure.
- Invariant violations panic with an error value (not a returned error, not a plain-string panic).
- Constructors over struct literals (required for domain models); interfaces returned from
  action/repository/client constructors with unexported implementations.
- Boolean parameters replaced by enums; named returns absent; multi-return beyond `error` justified.
- IO takes `ctx` first; pure functions don't; tests use `t.Context()`.
- Imports grouped in three blocks; `any` over `interface{}`; no dot imports.
- Test helpers use `t.Helper()` / `t.Cleanup()`; testify used.
- Docstrings start with the identifier, imperative present tense; `//` comments only.
