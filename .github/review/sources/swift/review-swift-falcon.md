# Muun Swift / Falcon Review Conventions

Sources: `falcon/CLAUDE.md` (hard conventions) + PR review patterns distilled from the 50 most
recent merged PRs touching `falcon/` (#15933–#16702, ~210 reviewer comments).

Falcon reviews tend to run file-by-file and socratic — most feedback is phrased as a question and
discussed to agreement. Findings below are ordered by how often reviewers actually flag them.

Layer flow (from `falcon/CLAUDE.md`, section "Architecture"):
**gRPC proto -> Repository/Service -> Action -> Presenter -> View**

## Often flagged

### 1. Architecture & separation of concerns

- **Logic and state belong in the presenter, not the view controller.** ViewControllers must not
  hold domain models; presenters inherit from `BasePresenter<Delegate>`, take domain models in
  `init`, and expose view-ready data via the delegate protocol. ([#16345](https://github.com/muun/muun/pull/16345), `falcon/CLAUDE.md` "Presenter pattern")
- **Don't fight the UIKit lifecycle with ad-hoc flags** (e.g. a `hasLoaded` boolean) — get the
  value at the right lifecycle point instead. ([#16433](https://github.com/muun/muun/pull/16433))
- **Services shouldn't quietly accumulate responsibilities.** Business logic and infra logic in
  one growing class is a flag — split responsibilities. ([#16183](https://github.com/muun/muun/pull/16183))
- **Delegates over closures** for view communication: `protocol FooDelegate: AnyObject` + `weak
  var delegate`. Never `var onSomething: (() -> Void)?`. (`falcon/CLAUDE.md` "Delegates over closures")
- **Inject required delegates in `init`** — don't rely on setting a property after construction.
  (`falcon/CLAUDE.md` "Inject delegates in init")
- **Cells receive only what they need** — primitives or small view-model structs, not full domain
  models when the cell uses one field. (`falcon/CLAUDE.md` "Cell configuration")
- **Shared logic belongs in libwallet, not Swift.** Functionality Apollo could also use (file
  operations, data processing, domain logic) defaults to `libwallet/`; Falcon keeps only
  platform-specific concerns. (`falcon/CLAUDE.md` "Libwallet")

### 2. Design tokens & theming

- **No hardcoded colors or spacing — go through `MuunTheme`** (`MuunTheme.Color.Text.bodyPrimary`,
  `MuunTheme.Spacing.md`, `MuunTheme.Font.Body.md`). Light/dark resolution happens automatically.
  ([#16433](https://github.com/muun/muun/pull/16433), `falcon/CLAUDE.md` "Design System")
- **The legacy palette (`Asset.Colors.muun*`, etc.) is deprecated** for new code, as are UIKit
  system colors (`.systemBackground`, `.gray`). (`falcon/CLAUDE.md` "Colors")
- **Fonts via `Constant.Fonts.system(size:weight:)`** with semantic sizes from
  `Constant.FontSize`, not `.systemFont(ofSize:weight:)`. (`falcon/CLAUDE.md` "Fonts")
- **Be consistent about inline tokens vs named constants within a view** — if sibling views use
  inline `MuunTheme.Spacing.xl`, don't mix criteria without a reason. ([#16356](https://github.com/muun/muun/pull/16356), [#16118](https://github.com/muun/muun/pull/16118))
- **Magic numbers**: extract a literal into a named constant when it has semantic meaning (ratio,
  threshold, tuned value) or is reused; obvious one-off values (`stackView.spacing = 8`) may stay
  inline. Constants live inside the class (`private enum Constants`), never at file scope.
  (`falcon/CLAUDE.md` "Magic numbers")

### 3. Commit scope & hygiene

- **The diff should match the commit message and nothing more.** ([#16118](https://github.com/muun/muun/pull/16118))
- **Watch for stray `Podfile.lock` / `Package.resolved` / `project.pbxproj` changes** that don't
  belong to the change being made. ([#16158](https://github.com/muun/muun/pull/16158))
- **No leftover debug code** — revert debugging changes before requesting review. ([#16121](https://github.com/muun/muun/pull/16121))
- **New `.swift` files include their `.pbxproj` change in the same commit.** (`falcon/CLAUDE.md` "Commits")
- **Commit prefixes**: `falcon:` for iOS-only changes, `falcon,libwallet:` for cross-module.
  (`falcon/CLAUDE.md` "Commits")

## Regularly flagged

### 4. Error handling

- **No silent failures.** If a fetch fails and the UI desyncs silently, decide deliberately: show
  an error, log, or both. ([#16433](https://github.com/muun/muun/pull/16433), [#16257](https://github.com/muun/muun/pull/16257))
- **`fatalError` on unreachable invariants is fine and idiomatic** — the `init(coder:)`
  boilerplate, abstract-method placeholders, and programmer-error asserts (failed cell dequeue,
  missing asset) are widespread in the codebase and are not review findings.
- **Crashing on a reachable runtime failure is a product decision, not a default** — a failed
  fetch, missing data, or unexpected external input. A crash costs the chance to send an in-app
  bug report; prefer degraded-but-reportable behavior. ([#16183](https://github.com/muun/muun/pull/16183))

### 5. Concurrency & gRPC lifecycle

- **Guard mutable shared state** — if a client/channel became mutable, guard access while a
  request is in flight. ([#16099](https://github.com/muun/muun/pull/16099))
- **Respect the ~5s budget when entering background** — the OS kills the app shortly after
  `didEnterBackground`; prefer non-blocking completion (`whenComplete`) over `wait`. ([#16099](https://github.com/muun/muun/pull/16099))
- **Shut down channels gracefully** — `close()` can cancel in-flight RPCs (e.g. a libwallet write
  could be lost); prefer `closeGracefully`. Watch for stale channels being reused. ([#16229](https://github.com/muun/muun/pull/16229))

### 6. Tests

- Unit tests inherit from `MuunTestCase` (sets up the DI container); UI tests use accessibility
  identifiers defined in `Presentation/PageObject/UIElement.swift`. (`falcon/CLAUDE.md` "Testing")
- **Cover the edge cases** — including negative cases ("check that something crazy like NGN is
  NOT on the list"). ([#16476](https://github.com/muun/muun/pull/16476))
- **Prefer `throws` test methods over `try!`** — a thrown error fails one test instead of
  crashing the whole suite. ([#16007](https://github.com/muun/muun/pull/16007))
- **Keep tests consistent with each other** and make failures readable. ([#16007](https://github.com/muun/muun/pull/16007))
- **Test persistence-sensitive behavior** — e.g. does the data survive a wipe of the persistent
  keys? ([#16007](https://github.com/muun/muun/pull/16007))

### 7. Reuse & DRY

- **Extract duplicated logic** — if the same formatting/parsing exists elsewhere (e.g. another
  formatter), extract and reuse. ([#16345](https://github.com/muun/muun/pull/16345), [#16007](https://github.com/muun/muun/pull/16007))
- **Lift genuinely shared VC behavior into `MUViewController`** instead of copying it across
  screens. ([#16256](https://github.com/muun/muun/pull/16256))
- **Use the project's type-safe UIKit extensions** (`tableView.register(type:)`,
  `dequeue(type:indexPath:)`) instead of string-based registration. (`falcon/CLAUDE.md` "UIKit Extensions")

### 8. Naming

- **Avoid generic class names.** ([#16356](https://github.com/muun/muun/pull/16356))
- **Method names should reflect what they actually do.** ([#16256](https://github.com/muun/muun/pull/16256))
- **Introduce a small named type when it clarifies intent** — e.g. a `BalanceAmount` struct
  instead of reconstructing loose fields. ([#16475](https://github.com/muun/muun/pull/16475))

### 9. iOS lifecycle & navigation

- **Check back navigation** — nav bar appearance, large titles, restored state. Restore
  appearance in `viewWillDisappear` when the screen customized it. ([#16118](https://github.com/muun/muun/pull/16118))
- **Mind `MUViewController` lifecycle interactions** — values set locally can be overwritten by
  the base class in `viewWillAppear` when navigating back. ([#16210](https://github.com/muun/muun/pull/16210))
- **Group lifecycle overrides together** in the file. ([#16118](https://github.com/muun/muun/pull/16118))

### 10. Dead code, unused params & duplicated state

- **Remove unused parameters and dead strings.** ([#16475](https://github.com/muun/muun/pull/16475))
- **Cut redundant conditions** — e.g. `rate > 0 && !rate.isNaN` is redundant because
  `Double.nan > 0` is already false. ([#16476](https://github.com/muun/muun/pull/16476))
- **Don't store state another object already owns.** ([#16356](https://github.com/muun/muun/pull/16356))
- **No implicit state from UI properties** — don't derive logic from `view.alpha == 0` or
  `view.isHidden`; track an explicit `private var` boolean. (`falcon/CLAUDE.md` "No implicit state from UI properties")

## Occasionally flagged

### 11. Cross-platform consistency with Apollo

- **When in doubt, match how Apollo already does it** — naming, behavior, and data types (e.g.
  Apollo uses satoshis directly). ([#16183](https://github.com/muun/muun/pull/16183), [#16475](https://github.com/muun/muun/pull/16475))

### 12. Style & formatting

- Multi-line parameter formatting, consistent indentation, one condition per line. Mostly caught
  by SwiftFormat/SwiftLint — fix before review. ([#15933](https://github.com/muun/muun/pull/15933), [#16476](https://github.com/muun/muun/pull/16476))
- **No spurious SwiftLint suppressions** — only add `// swiftlint:disable` when a specific rule
  actually fires on that line. (`falcon/CLAUDE.md` "No spurious SwiftLint suppressions")

### 13. Documentation & accepted debt

- **Leave a comment when behavior is subtle or has a side effect.** ([#16395](https://github.com/muun/muun/pull/16395))
- **When deferring a fix, drop a TODO and open a GH issue** so it isn't lost. ([#16476](https://github.com/muun/muun/pull/16476))

## Hard conventions (always in scope)

These come from `falcon/CLAUDE.md` and apply mechanically regardless of review frequency:

- **Localization**: all user-facing text via `L10n.ClassName.keyName`, with entries in both
  `en.lproj` and `es.lproj` and regenerated `Strings+Generated.swift`. Never inline string
  literals for UI text. (`falcon/CLAUDE.md` "Strings")
- **Analytics**: typed `AnalyticsEvent` structs under `core/Analytics/Events/` logged via
  `AnalyticsHelper.logEvent(event)`; never the deprecated `logEvent("name", ...)` string form.
  Parameter values conform to `AnalyticsValue`. (`falcon/CLAUDE.md` "Analytics")
- **Dependency injection** via Dip's global `resolve()`; registration in
  `DependencyContainer.swift`. (`falcon/CLAUDE.md` "Architecture")

## Also watched

Lower-frequency themes reviewers still bring up:

- Retain cycles / `[weak self]`
- Main-thread blocking and loading states
- Product/UX trade-offs (e.g. share sheet vs email)
- New features via SPM to avoid `pbxproj` conflicts
- Behavior changes documented in the PR description
- Cleanup of temp files and resources

## What Reviewers Check

- Is any logic or state living in a VC that belongs in a presenter?
- Are all colors, spacing, and fonts going through `MuunTheme` / `Constant.Fonts` (no legacy
  palette, no system colors, no hardcoded values)?
- Does every commit's diff match its message? Any stray lockfile/pbxproj noise or debug leftovers?
- Are failures handled deliberately (error shown, logged, or consciously ignored)? Any crash on
  a reachable runtime failure that would cost a bug report? (invariant `fatalError`s are fine)
- Is mutable shared state guarded? Are gRPC channels closed gracefully and background work within
  the ~5s budget?
- Do tests cover edge and negative cases, use `throws` over `try!`, and inherit the right base?
- Is anything duplicated that already exists (formatters, VC behavior, helpers)?
- Do names (classes, methods) say what they do? Would a small named type clarify?
- Was back navigation checked (nav bar, large titles, `MUViewController` overwrites)?
- Any unused params, dead strings, redundant conditions, duplicated state, or state derived from
  UI properties?
- Does the change match Apollo's naming/behavior/types where a counterpart exists? Should the
  logic live in libwallet instead?
- Are all user-facing strings localized and analytics events typed?
