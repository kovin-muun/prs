# Muun Testing Standards

Source: Notion ["On testing"](https://www.notion.so/707f6a3cd3d6493980a2134fc97202e2), ["Our practices"](https://www.notion.so/b125a87b52de4906bd6f99670e3e635f), ["Muun-specific best practices"](https://www.notion.so/5e0f40684a304dc097298433b5a8917f) + PR patterns.

Validated against codebase:
- [`RoutingResourceTest.java` @ b665b573](https://github.com/muun/muun/blob/b665b573351e1c686f5e293f47f70d0698270c3d/forwarder/src/test/java/io/muun/forwarder/presentation/RoutingResourceTest.java)
- [`TestModule.java` @ f8bfcac5](https://github.com/muun/muun/blob/f8bfcac5e3f4121095dc1069071fa7dc69ddb31a/forwarder/src/test/java/io/muun/forwarder/TestModule.java)
- [`BitcoindClientTest.java` @ 62c48510](https://github.com/muun/muun/blob/62c48510a5680382ff4d59a7f98b70b982677056/clients/src/test/java/io/muun/clients/bitcoind/BitcoindClientTest.java)

## Philosophy
Source: Notion ["On testing"](https://www.notion.so/707f6a3cd3d6493980a2134fc97202e2), sections "On testing" and "Final words"
Relevant quote: "We write tests for three equally important reasons: 1. To increase the confidence in the code's correctness. 2. To reduce regressions during refactors. 3. As documentation. ... the combination of 1. and 2. is a key part of having confidence for CD."
Relevant quote: "We want tests to be maintainable, and ideally to serve as functional documentation. ... we also understand that tests have a maintenance cost, and can easily become a friction point to evolve and refactor the codebase: this leads us to delete tests that are not enhancing the confidence in the correct working of the system."
Relevant quote: "We want deploys to be as smooth as possible: this leads us to invest in hunt and kill the flakiness of the tests."
Relevant quote (Final words): "We want the test suite to run in less than 15min: this leads us to want to use the 'leanest' version possible of testing that provides us the certainty we are looking for."

Source: Notion ["Our practices"](https://www.notion.so/b125a87b52de4906bd6f99670e3e635f), section "On tests"
Relevant quote: "adding tests to new functionality is required. There are some notable exceptions like presenters and actions in mobile clients and some legacy parts of Houston."

- Testing diamond (not pyramid): `Unit < Integration > E2E`
- Tests exist for three reasons: correctness, regression prevention, documentation
- Together these enable confidence for Continuous Delivery
- New functionality requires tests (non-negotiable, with some exceptions: presenters and actions in mobile clients, and some legacy parts of Houston)
- Tests should be maintainable and serve as functional documentation
- Delete tests that don't enhance confidence — they have maintenance cost
- Hunt and kill flakiness
- Test suite should run in less than 15 minutes — prefer the leanest test strategy that gives sufficient certainty

## Test Runners (decreasing scope)

Source: Notion ["On testing"](https://www.notion.so/707f6a3cd3d6493980a2134fc97202e2), section "Runners"

### BaseIntegrationTest
- Tests many code units together with real dependencies (DB, migrations, regtest, other services)
- Preferred for testing public APIs / endpoint-level testing
- Provides compliant environment setup, test config, service helpers, automatic tracing
- Example: `io.muun.funder.domain.action.utxo_set.ComputeTransactionPacksActionTest`

### @Category(DockerTest.class)
- Real environment (DB, regtest) but without full service startup
- Foundation for BaseIntegrationTest but with less setup
- Migrations won't run automatically — use BaseIntegrationTest if needed
- Example: `io.muun.clients.bitcoind.BitcoindClientTest`

### @RunWith(MockitoJUnitRunner.class)
- For non-pure actions with dependencies that need mocking
- Example: `io.muun.funder.domain.action.utxo_set.ComputeTransactionsFeesActionTest`

## Testing Strategies

Source: Notion ["On testing"](https://www.notion.so/707f6a3cd3d6493980a2134fc97202e2), section "Testing strategies"

### Integration tests (preferred)
- Test from the presentation layer — call the service's public API using its client
- Do NOT call resource instance methods directly
- Patch client to avoid timeouts while debugging (see `io.muun.forwarder.TestModule`)
- Example: `io.muun.forwarder.presentation.RoutingResourceTest`

### Mocking in integration tests
- `@RunWith(MockitoJUnitRunner.class) + BaseIntegrationTest`
- Construct tested action manually (no auto DI), providing mocks in `@Before setUp`
- Example: `io.muun.funder.domain.action.utxo_set.UtxoSetCacheTest`

### Mocking without full service
- `@RunWith(MockitoJUnitRunner.class) + @Category(DockerTest.class)`
- Test integration of 2+ units without full service startup
- Example: `io.muun.syncer.domain.action.fetching.FetchBlockActionTest`

### Deep mocking (whole service)
- Extend DI system with a module for mocked dependencies
- Example: `io.muun.syncer.app.di.HoustonClientModule`

### Pure unit tests
- Direct instantiation, call methods, assert results
- No mocking needed
- Example: `io.muun.funder.domain.model.draft.FundingTransactionDraftTest`

## Test Categories
Source: Notion ["Muun-specific best practices"](https://www.notion.so/5e0f40684a304dc097298433b5a8917f), section "Tests"
Relevant quote: "There are some kinds of tests that we don't want running on CI each time we commit. We have special JUnit categories to exclude them from being run: DockerTest: for those that involve extra resources like DBs for integration tests, so they need to be run in a dockerized env. StressTest: for those that are intended for benchmarking."

- No annotation = pure unit tests (run in `:test`)
- `@Category(DockerTest.class)` = needs Docker env (run in `:testAll`, CI/pre-merge)
- `@Category(StressTest.class)` = benchmarks (manual only, `:stressTest`)

## Assertions
Source: Notion ["Muun-specific best practices"](https://www.notion.so/5e0f40684a304dc097298433b5a8917f), section "Tests"
Relevant quote: "We use org.assertj.core.api.Assertions for assertions, which offers more detailed error descriptions than plain asserts."

- Use `org.assertj.core.api.Assertions` (more detailed error descriptions than plain assert)

## Periodic Actions in Tests
Source: Notion ["On testing"](https://www.notion.so/707f6a3cd3d6493980a2134fc97202e2), section "Caveats — Periodic actions"

- Background/periodic actions don't run by default in integration tests
- Start normally: `getApplication().startPeriodicAction(PeriodicAction.class)`
- Run once: `getApplication().runPeriodicActionOnce(PeriodicAction.class)`
- Background action: `getApplication().startBackgroundAction("name")`

## Caveats
Source: Notion ["On testing"](https://www.notion.so/707f6a3cd3d6493980a2134fc97202e2), section "Caveats"

- DI mocking in tests doesn't cascade to all instances automatically
- `@VisibleForTesting` should be avoided (indicates leaky abstraction) — consider if it should be a separate code unit
- Static imports allowed in tests but not in production code

## What Reviewers Check
- Are tests present for new functionality?
- Do tests cover edge cases and corner cases?
- Are tests testing via the public API / client (not internal methods)?
- Do tests serve as documentation of intended behavior?
- Is the right test runner being used?
- Are assertions using assertj?
