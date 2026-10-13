# Muun Libwallet Conventions

Source: Notion ["Libwallet conventions guide"](https://www.notion.so/35ec8573de2c80a8b92bed843da085b3) + codebase patterns.
Relevant quote: "Libwallet is the local backend for the mobile apps (Apollo & Falcon). Treat it like backend code. For language-level rules see the Go style-conventions guide."

These rules apply **only to code under `libwallet/`**. They extend the general Go rules in
`review-go-style.md` — apply both to libwallet files; apply only `review-go-style.md` to Go outside
`libwallet/`. `libwallet/CLAUDE.md` carries the same architecture with more detail (design and
testing guidelines distilled from review); where the two disagree, `libwallet/CLAUDE.md` wins.

Validated against codebase: the `marketplace` subsystem, which follows the target layout:
[`marketplace.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/subsystems/marketplace/presentation/marketplace.go), [`marketplace.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/subsystems/marketplace/internal/presentation/marketplace.go), [`wiring.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/subsystems/marketplace/wiring.go), [`fetch_card_offer_action.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/subsystems/marketplace/internal/domain/action/fetch_card_offer_action.go), [`marketplace_repository.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/subsystems/marketplace/internal/data/marketplace_repository.go)

## Architecture
Source: Notion ["Libwallet conventions guide"](https://www.notion.so/35ec8573de2c80a8b92bed843da085b3), section "Architecture overview"

Libwallet is organized into **subsystems**: functional areas with explicit public APIs. Shared
wallet concepts and data access live in `base/`. Infrastructure independent of wallet behavior
lives in `platform/`.

The domain/data split applies at two scopes:

- Within a subsystem, `internal/domain/` owns its models and actions; `internal/data/` owns its
  persistence and external-service adapters.
- Across subsystems, `base/domain/` holds shared domain concepts and pure operations; `base/data/`
  holds shared persistence and external-service access.

Dependency rules:

1. Subsystems depend on other subsystems only through their `presentation/` interfaces and
   `presentation/model/` types.
2. `base/domain/` is independent of persistence, external services and subsystems.
3. `base/data/` may depend on shared domain and platform packages, never on subsystems.

The import rules are enforced by the `muun_subsystem_boundary` linter and `depguard` in
`.muun-golangci.yml`; review still reports violations it sees.

## Package Layout
Source: Notion ["Libwallet conventions guide"](https://www.notion.so/35ec8573de2c80a8b92bed843da085b3), section "Package layout"

```
platform/              shared non-functional infrastructure (observability, concurrency,
                       security utilities, test support). Domain logic never lives here.
base/domain/           shared domain
base/data/             shared persistence and service adapters
subsystems/<name>/     libwallet functional components
app_provided_data/     native bridge contracts
server/                gRPC server, interceptors, proto definitions
libwallet_init/        dependency wiring and server startup
legacy/                pre-subsystems code
```

`server/` maps protobuf messages to and from subsystem presentation types and calls subsystem
presentation interfaces. Anything that doesn't fit this structure is legacy (see "Legacy Code").

## Subsystems
Source: Notion ["Libwallet conventions guide"](https://www.notion.so/35ec8573de2c80a8b92bed843da085b3), section "Subsystems"
Validated against codebase: [`marketplace.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/subsystems/marketplace/presentation/marketplace.go), [`marketplace.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/subsystems/marketplace/internal/presentation/marketplace.go), [`wiring.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/subsystems/marketplace/wiring.go)

- **Contract**: `presentation/` is a single file named after the subsystem that exports one
  interface named after it, one method per operation. Concrete boundary types live in
  `presentation/model/`. No business implementation details in either.
- **Internal packages**:
  - `internal/presentation/`: a single file named after the subsystem, exporting a struct of the
    same name plus its constructor.
  - `internal/domain/action/`: actions that orchestrate the subsystem's behavior.
  - `internal/domain/model/`: internal domain models.
  - `internal/data/`: the subsystem's repositories and adapters.
  - `internal/test/`: the subsystem's non-integration tests and test utilities.
- **Wiring**: `wiring.go` is the only Go file at the subsystem root. It builds the repositories and
  actions, passes them to the `internal/presentation` constructor, re-exports the implementation
  struct under the subsystem's name, and returns it by value.

## Actions
Source: Notion ["Libwallet conventions guide"](https://www.notion.so/35ec8573de2c80a8b92bed843da085b3), section "Actions"
Validated against codebase: [`fetch_card_offer_action.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/subsystems/marketplace/internal/domain/action/fetch_card_offer_action.go), [`wiring.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/subsystems/marketplace/wiring.go)

Actions are domain logic in `internal/domain/action/`.

- An action is an exported interface with a single `Run(...)` method, declared in the action's own
  file. The implementation is an unexported struct.
- The exported `Run` method has a brief comment explaining what it does.
- The constructor `NewXxxAction(deps...)` returns the interface, never the struct.
- Actions are built in the subsystem's `wiring.go` and passed to the `internal/presentation`
  struct. Consumers never see actions; they call the subsystem's interface.

## Repositories
Source: Notion ["Libwallet conventions guide"](https://www.notion.so/35ec8573de2c80a8b92bed843da085b3), section "Repositories"
Validated against codebase: [`marketplace_repository.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/subsystems/marketplace/internal/data/marketplace_repository.go)

> 🚧 Repository conventions are not yet solidified — treat findings here as soft.

Subsystem repositories live in `internal/data/`, shared ones in `base/data/`. Same shape as
actions: an exported interface with an unexported implementation.

- Repositories return pointers consistently. A pointer signals nullability; consistency across
  methods is preferred over per-method optimization.

## Models
Source: Notion ["Libwallet conventions guide"](https://www.notion.so/35ec8573de2c80a8b92bed843da085b3), section "Models"
Validated against codebase: [`preconditions.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/platform/preconditions/preconditions.go)

- Two roles: `internal/domain/model/` holds internal domain models (state, values, invariants);
  `presentation/model/` holds the public types used in the subsystem's interface.
- Model structs are exported, with public fields.
- Construction is gated through `NewModel(...)`; validations live in the constructor. Never
  inline-initialize a model with `&Model{...}` outside its package.
- Use the `platform/preconditions` package for validations inside models.
- Action-specific helper structs live alongside the action that uses them, not in
  `internal/domain/model/` or `presentation/model/`.

## Native OS Integration
Source: Notion ["Libwallet conventions guide"](https://www.notion.so/35ec8573de2c80a8b92bed843da085b3), section "Native OS integration"
Validated against codebase: [`key_provider.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/app_provided_data/adapted/key_provider.go)

When libwallet needs an iOS/Android API, the contract is a `Provider` interface in
`app_provided_data/`; native code implements it via gomobile bridging.

- A Go-typed adapter that only converts and validates bridge values lives in
  `app_provided_data/adapted/`. Wrappers that add behavior live with their owning functionality, in
  `base/data/` or the subsystem.
- Actions depend on the adapted interface or a domain-friendly wrapper, never on the raw bridge
  interface.

## Logging
Source: Notion ["Libwallet conventions guide"](https://www.notion.so/35ec8573de2c80a8b92bed843da085b3), section "Observability"

> ⚠️ Observability conventions are not yet solidified — treat findings here as soft.

- Logs currently reach the native layer through a custom `slog.Handler`.

## Testing
Source: Notion ["Libwallet conventions guide"](https://www.notion.so/35ec8573de2c80a8b92bed843da085b3), section "Testing"
Validated against codebase: [`base_integration_suite.go` @ 91b87183](https://github.com/muun/muun/blob/91b87183bc417c48a23c4024e15316bc14701acf/libwallet/platform/test/testsuite/base_integration_suite.go)

Integration tests on the domain layer are the primary testing strategy. Unit tests are useful for
edge-case-heavy logic but don't replace integration tests.

Tests use testify for assertions and suites, and mockery to generate interface mocks. Source:
codebase pattern — no mockery config or generated mocks exist in the repo yet
(as of 91b87183), so the first change that needs a mock of an interface sets it up; a hand-written
fake of a plain interface is a finding.

### Integration tests
Standard scaffolding:

```go
package enforcer_test

import "github.com/muun/libwallet/platform/test/testsuite"

func TestEnforcer_Integration(t *testing.T) {
    testsuite.Run(t, new(EnforcerTestSuite))
}

type EnforcerTestSuite struct {
    testsuite.BaseIntegrationSuite
    // ... shared deps
}

func (s *EnforcerTestSuite) SetupSuite() {
    s.BaseIntegrationSuite.SetupSuite()
    // shared resources: bitcoind client, electrum client, repositories
}

func (s *EnforcerTestSuite) SetupTest() {
    s.BaseIntegrationSuite.SetupTest()
    // per-test fresh state
}
```

- Subsystem integration tests live in `subsystems/<name>/presentation/tests/`, in an external test
  package, and exercise the subsystem through its presentation interfaces.
- Entry point: `TestXxx_Integration(t *testing.T)` calling `testsuite.Run()`.
- The suite struct embeds `testsuite.BaseIntegrationSuite`.
- `SetupSuite()` for shared resources initialized once; `SetupTest()` for per-test fresh state.
  When overriding either, call the `BaseIntegrationSuite` equivalent, as in the example above.
- Share logic across related suites by embedding a custom base suite (that itself embeds
  `BaseIntegrationSuite`).

### Unit tests
- May use plain `testing.T`; suite scaffolding is mostly for the integration layer.
- Live in `internal/test/`, not as `_test.go` files next to the code.

## Legacy Code
Source: Notion ["Libwallet conventions guide"](https://www.notion.so/35ec8573de2c80a8b92bed843da085b3), section "Legacy code"

Libwallet began as a cryptography-sharing library exposed via gomobile, which forced all public API
into the top-level package and `newop/`, producing a flat organization. `legacy/` preserves
pre-muun3 behavior required for perpetual backward compatibility and self-custody. Both
architectures co-exist.

- New code must follow the layered architecture above.
- Legacy code should be migrated when it is refactored. Don't flag the mere existence of legacy
  code as a defect, but new code must not be added to it.

## What Reviewers Check
- New functionality lives in a subsystem (or `base/` for shared domain/data), not in `legacy/` or
  new top-level packages.
- Cross-subsystem use goes through `presentation/` interfaces and `presentation/model/` types only;
  `base/domain/` stays free of persistence, services and subsystems; `base/data/` never imports a
  subsystem.
- Subsystem shape: single-file one-interface contract, `internal/{presentation,domain,data,test}`,
  `wiring.go` as the only root file building actions and returning the implementation by value.
- Actions: exported interface with one commented `Run` + unexported impl + `NewXxxAction`
  returning the interface, built in `wiring.go`.
- Repositories: interface + unexported impl, pointers returned consistently.
- Models: exported fields, gated through `NewModel(...)` with `platform/preconditions`
  validation; no `&Model{...}` outside the package; action helpers not in `model/`.
- Native integration: `Provider` in `app_provided_data/`, adapter in `adapted/`, actions never
  depend on the raw bridge interface.
- Tests: integration tests in `presentation/tests/` with the `BaseIntegrationSuite` scaffolding;
  other tests in `internal/test/`; testify assertions; mockery mocks rather than hand-written
  fakes of plain interfaces.
