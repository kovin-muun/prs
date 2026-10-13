# Muun Kotlin Style Conventions

Kotlin code follows `review-java-style.md`. This file lists only the **Kotlin-specific extensions and emphases** — rules that don't appear in the Java guide, or that need adjustment for Kotlin syntax. Where this file is silent, follow the Java guide.

Sources: [Android Kotlin style guide](https://developer.android.com/kotlin/style-guide), [Muun Java style guide](https://www.notion.so/Java-style-conventions-guide-c55efc19d00d48f586bd8d4cb59d6e6b?pvs=21), PR review patterns.

## Control flow

### Braces

Always use braces for `if`, `for`, `while`, `do`, and `try`/`catch` — including empty bodies and single-statement bodies. `when` arrow branches may be brace-free for single statements: `0 -> doSomething()` ([#12563](https://github.com/muun/muun/pull/12563#pullrequestreview-2325777709), [#15604](https://github.com/muun/muun/pull/15604#pullrequestreview-4069664242), [#16123](https://github.com/muun/muun/pull/16123#pullrequestreview-4274325007), [#16128](https://github.com/muun/muun/pull/16128#pullrequestreview-4276703377))

Bad:

```kotlin
if (string.isEmpty()) return
val result = if (string.isEmpty()) DEFAULT_VALUE else string
```

Good:

```kotlin
if (string.isEmpty()) {
    return
}

val result = if (string.isEmpty()) {
    DEFAULT_VALUE
} else {
    string
}
```

### Function bodies

For non-`Unit` functions, prefer block body with an explicit `return` over expression-body syntax (`fun foo() = ...`). Implicit returns hurt readability; when in doubt, choose the explicit form. ([#16123](https://github.com/muun/muun/pull/16123#pullrequestreview-4274325007))

Bad:

```kotlin
private fun displayName(user: User): String =
    user.firstName + " " + user.lastName
```

Good:

```kotlin
private fun displayName(user: User): String {
    return user.firstName + " " + user.lastName
}
```

## Recent reviewer style feedback on `.kt` files

### Idiomatic Kotlin

- **AVOID `!!` at all costs,** it breaks null safety. If you could produce a NullPointerException you’re against an [architectural design](https://kotlinlang.org/docs/null-safety.html) of the language. ([#16030](https://github.com/muun/muun/pull/16030#pullrequestreview-4222135148))
  - `!!` could be replaced with:
    `requireNotNull(x) { "..." }`
    `x ?: throw IllegalStateException("something is wrong")`
- **Use scope functions for null-safe chains.** `nullable?.let { target.withX(it) }` is preferred over branching on null. ([#16086](https://github.com/muun/muun/pull/16086#pullrequestreview-4244281760))

### Constants and literals

- **Extract repeated string/number literals into named constants.** Especially when the same value appears in multiple places (`ChallengeKey.*` style refs, timeouts reused across call sites). ([#15844](https://github.com/muun/muun/pull/15844#pullrequestreview-4114825965), [#15889](https://github.com/muun/muun/pull/15889#pullrequestreview-4173204266), [#15937](https://github.com/muun/muun/pull/15937#pullrequestreview-4148143272))
- Constants go at the top of the object ([#16123](https://github.com/muun/muun/pull/16123#pullrequestreview-4292157572))

### Imports and references

- **Import classes — don't use FQDN inline.** Not even in tests. ([#15889](https://github.com/muun/muun/pull/15889#pullrequestreview-4173204266), [#15889](https://github.com/muun/muun/pull/15889#pullrequestreview-4173204266))
- **No star imports** (`import foo.bar.*`). ([#16124](https://github.com/muun/muun/pull/16124#pullrequestreview-4274205620))

### Comments and docs

- **Keep comments and KDoc in sync with code.** Stale docstrings (especially after recent refactors in the same PR) get flagged; either update or delete. ([#16030](https://github.com/muun/muun/pull/16030#pullrequestreview-4205855835), [#15904](https://github.com/muun/muun/pull/15904#pullrequestreview-4164752688), [#15904](https://github.com/muun/muun/pull/15904#pullrequestreview-4164987525))

### Reuse over duplication

- **Reuse existing helpers; don't reinvent.** Before adding a new helper, check shared util classes, and the rest of the surrounding codebase. ([#16075](https://github.com/muun/muun/pull/16075#pullrequestreview-4236845891))
- **Extract helpers when call sites repeat shape.** When the same boilerplate appears across multiple call sites, propose a helper. ([#16075](https://github.com/muun/muun/pull/16075#pullrequestreview-4228907329))

### Naming and organization

- **Rename for clarity when a name doesn't convey the role.** Naming nits are common and worth applying. ([#15904](https://github.com/muun/muun/pull/15904#pullrequestreview-4156975369))
- **Co-locate files with their domain neighbors.** Move misplaced files into the package where their siblings live. ([#15904](https://github.com/muun/muun/pull/15904#pullrequestreview-4150903622))
- **Remove redundant declarations.** ([#15904](https://github.com/muun/muun/pull/15904#pullrequestreview-4156971324))
- **Don't declare functions inside functions** unless there's a strong reason — extract to a private member instead. ([#15581](https://github.com/muun/muun/pull/15581#pullrequestreview-3946249691))

### Android-specific (Compose / MVI)

- **ViewModel method names are actions, not events.** `purchaseCard()`, not `onCardPurchased()`. ([#15884](https://github.com/muun/muun/pull/15884#pullrequestreview-4116178157))
- **One-shot events go through `MutableSharedFlow<ViewCommand/ViewEvent>`,** not `UiState`. State held in `UiState` re-fires on configuration changes (e.g. modals re-trigger on rotation). ([#15884](https://github.com/muun/muun/pull/15884#pullrequestreview-4116137931))
- **Screen-displayed content belongs in `UiState`,** not constructed ad-hoc in composables. ([#15884](https://github.com/muun/muun/pull/15884#pullrequestreview-4116236028))
- **Strings should be localizable resources,** not hardcoded literals in UI code. ([#15884](https://github.com/muun/muun/pull/15884#pullrequestreview-4116213531))

### Tests (emerging convention)

From [#15889](https://github.com/muun/muun/pull/15889#pullrequestreview-4183367527):

- **Test names** in the form `should <do X>` or `<doing X> should <Y> [when <Z>]`. Avoid generic names that don't describe behavior.
- **Test body structure**: explicit GIVEN / WHEN / THEN sections; no assertions inside GIVEN.
- **Don't re-test logic already covered** by another test's GIVEN setup.
- **Prefer `expected` / `actual`** terminology over `want` / `got`.