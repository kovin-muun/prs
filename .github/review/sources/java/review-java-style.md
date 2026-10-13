# Muun Java Style Conventions

Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b) + PR review patterns.
Relevant quote: "We have two goals in mind when choosing our code style: 1. Readability — Code will be read a lot so we optimize for reading. 2. Consistency — readers should not need to make an effort to understand the structure of the code since it will always be the same."

Validated against codebase:
- [`SwapperApplication.java` @ 237c5808](https://github.com/muun/muun/blob/237c5808095b1a0fa0c67a2af79052ea41f5e3ad/swapper/src/main/java/io/muun/swapper/app/SwapperApplication.java)
- [`SubscribeToInFlightPaymentsAction.java` @ e02188be](https://github.com/muun/muun/blob/e02188befe27776e80e7ffeaa0e083e2499fd02d/forwarder/src/main/java/io/muun/forwarder/domain/action/outgoing/SubscribeToInFlightPaymentsAction.java)

## Goals
1. Readability — optimize for reading
2. Consistency — readers shouldn't struggle to understand code structure

## Formatting
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Basic rules"

- Line length: 100 characters
- Indents: 4 spaces
- One line break max between code units
- Unit separator on literal numbers: `1_123_456` not `1123456`

## Names
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Names"
Relevant quote: "Use descriptive names — Java is already verbose, lean into it. Don't abbreviate! They need extra effort by the reader to parse. Abbreviations are NOT all in upper case. Even in PascalCase, Utxo is good UTXO is bad."

Source (Honeycomb naming): Notion ["Muun-specific best practices"](https://www.notion.so/5e0f40684a304dc097298433b5a8917f), section "Honeycomb"
Relevant quote: "Tags should be named `<project name>:<tag name>` using snake_case for the tag name. Child traces are named with camelCase. Async actions created with JobRunner should also go with camelCase. Periodic action names are traced at Honeycomb by their name. These should be in camelCase as well."

- Descriptive names, no abbreviations — only use an abbreviation if readability is severely affected without it and the meaning is well understood (see abbreviation glossary: https://www.notion.so/a1e5c1bd9f0c4852975b2c17391ac37c)
- Abbreviations are NOT all-caps: `Utxo` good, `UTXO` bad. `EntityId` good, `EntityID` bad
- Quantities with basic types add unit suffix: `long amountInSats`. Prefer strong types: `Satoshis amount`
- Constants: `SCREAMING_SNAKE_CASE`, placed at top of class
- Variable for `FooAction` drops the suffix: `final DoSomethingAction doSomething`
- Honeycomb tags: `<project>:<tag_name>` in snake_case
- Child trace spans: camelCase
- Periodic action names: camelCase

## Operators
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Operators"

- When breaking expressions, operator starts the new line:
```java
final var sum = 10
        + 12;
```

## Control Flow
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Control flow"

- Always use braces (if, for, while, try-catch)
- Opening brace: last character of line
- Closing brace: first character of line
- Keywords and braces separated by exactly one space

## Ternaries
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Misc"

- Multi-line: condition and each value on separate lines:
```java
var option = aVeryLongBoolValue
        ? option1
        : option2;
```

## Classes
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Classes"

- Attributes and methods separated by one line from class declaration and from each other
- Field ordering: static final > static > @Inject final > final non-injected > non-final
- Constants at top
- Keep models in domain layer regardless of Hibernate annotations

## Constructors
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Constructors"

- Factory methods below properties, at top of constructors
- All constructors (public or private) at top, under properties or factory methods

## Methods
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Methods"

- Class (static) methods above instance methods
- Public above private, static above non-static
- First line may be empty if body > 2 lines
- Docstrings: imperative present tense ("Compute the fee" not "Computes the fee")
- `//` for inline comments, `/** */` for method/class docs

### Parameter formatting
- Multi-line: first param and closing `)` on their own lines:
```java
new DeviceCheckBanUserPayload(
    token
);
```
- When params on different lines, newline after `(`, `)` always on separate line
- On method declaration, if newline between first param and `(`, then `) {` on different line:
```java
private Single<Boolean> getDeviceCheckStatusFromPlainText(
        final String response,
        final JsonProcessingException e
) {
```

### Lambdas
- Anonymous method args that don't fit single line: param stays on same line as opening bracket:
```java
someMethod.run(lambdaParams ->
     doSomethingWithAReallyLongName(lambdaParams)
);
```

### Boolean Parameters
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Methods"

- Avoid boolean parameters — use explicit enums instead

## Properties
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Properties"
Relevant quote: "Prefer primitives instead of objects. Classes of the form SomethingJson.java are an important exception to this rule: we prefer objects over primitives there because primitives are always initialized with a default type, and their objects are immutable."

- Prefer primitives over objects — with two exceptions:
  - `SomethingJson.java` classes prefer objects since primitives have default values
  - Hibernate entity fields prefer boxed types (`Long`, `Boolean`, etc.) so that `null` signals uninitialized state and protects against partial-initialization mistakes
    Source: codebase pattern
    Validated against codebase: [`User.java` @ b1b3f1a8](https://github.com/muun/muun/blob/b1b3f1a8d888a53e8504bfd5072f5e065593b46a/houston/src/main/java/io/muun/houston/domain/model/User.java)
- Explicative comments go BEFORE annotations:
```java
// Foo objects are xyz
@FooLike
public Foo foo;
```
- `@Nullable` should have explaining comment when non-obvious
  Source: codebase pattern
  Validated against codebase: [`IncomingHtlc.java` @ c3ba3afb](https://github.com/muun/muun/blob/c3ba3afbd1c03ed84978831e4dc7addc019d9384/forwarder/src/main/java/io/muun/forwarder/domain/model/IncomingHtlc.java)

## Annotations
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Annotations"

- Strictly one annotation per line — never stack multiple annotations on the same line
  Source: codebase pattern (not stated explicitly in Notion; derived from all examples in the guide showing one annotation per line)
  Validated against codebase: [`IncomingHtlcRepository.java` @ 128bb904](https://github.com/muun/muun/blob/128bb904652eeb29a43c52bbd6b220b08cdf72ac/forwarder/src/main/java/io/muun/forwarder/data/repository/IncomingHtlcRepository.java)
- Place annotations as close to annotated thing as possible
- Class/field/variable/method annotations: above (not inline)
- Method parameter annotations: inline when possible, wrapped if too long

## Nullability
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Nullability"

- Everything under `io.muun` is non-null by default: un-annotated parameters, return types and
  fields are assumed never null. NullAway (ErrorProne) enforces this at build time — a missing
  `@Nullable` is a build error
- Annotate with `javax.annotation.Nullable` everything that can legitimately be null (fields,
  return types, parameters). Placement follows the Annotations rules: above the element for
  fields/methods, inline for parameters (e.g. `@Nullable final SwapJson swap`)
- `javax.validation.constraints.NotNull` (on `*Json` request models) is runtime request
  validation, not a nullness annotation — it neither replaces `@Nullable` nor conflicts with the
  non-null default
- Prefer making NullAway see the invariant over suppressing: a `Preconditions.checkNotNull(x)`
  call narrows `x` to non-null for the rest of the method
- `@SuppressWarnings("NullAway")` is allowed only when NullAway genuinely can't verify an
  invariant (e.g. `map.get(map.firstKey())` on a `SortedMap`) — say why in a comment
- Suppressions with a `// Pre-existing NullAway finding: fix in <issue>` comment are baselined
  tech debt: fix the code (or conclude the suppression is legitimate and drop the comment), never
  add new ones
- Hibernate entities are exempt from field-initialization checks (Hibernate populates fields
  reflectively). The default still applies to reads: annotate a field `@Nullable` if and only if
  its column is nullable

### Precondition placement
Source: [Slack #code (daro, Jul 2026)](https://muunbtc.slack.com/archives/C0FPKQ6RM/p1785474925692849?thread_ts=1784752825.095419&cid=C0FPKQ6RM)
Relevant quote: "estoy viendo multiples PRs llenar el código de inline preconditions en el medio de asignaciones random, haciendo todo más difícil de leer. pueden agregar una linea y usar la precondition como un single line statement. ahorrarse una linea no es un buen motivo para hacer el código más difícil de leer"

- A precondition (`Preconditions.checkNotNull`, `checkArgument`, `checkState`) must be a
  single-line statement: preferably a standalone assertion after a plain assignment, or an
  assignment whose entire right-hand side is the check
  (`final var x = Preconditions.checkNotNull(map.get(key));`)
- Never embed a precondition inside a larger expression. Flag any of these shapes:
  - as a call or constructor argument: `run(Preconditions.checkNotNull(map.get(k)), ...)`
  - as the receiver of a chained call: `Preconditions.checkNotNull(map.get(k)).addAll(txs);`
  - inside a boolean condition: `a == null || Preconditions.checkNotNull(m.get(b)) > threshold`
  - inside a stream or lambda: `.filter(tx -> !Preconditions.checkNotNull(tx.getWasBumpFailed()))`
  - nested in another precondition: `Preconditions.checkArgument(!Preconditions.checkNotNull(x));`
  - in the middle of a fluent chain: `.fetchByTxid(Preconditions.checkNotNull(req.getTxid()))`
- The fix is to spend the extra line — extract the checked value first, then use it plainly:
```java
// ❌
return isTxStateSafe(Preconditions.checkNotNull(txIdToState.get(utxo.getTxid())));

// ✅
final var txState = txIdToState.get(utxo.getTxid());

Preconditions.checkNotNull(txState);

return isTxStateSafe(txState);
```
- Inside a lambda, where extracting a line before isn't possible, use a block body with the
  check as its own statement — or extract a helper method:
```java
// ✅
.map(op -> {
    Preconditions.checkNotNull(op.getOnChainOutputIndex());
    return Outpoint.of(op.getOnChainTransactionId(), op.getOnChainOutputIndex());
})
```

### Prefer non-null by design over call-site checks
Source: [Slack #code thread (daro, Aug 2026)](https://muunbtc.slack.com/archives/C0FPKQ6RM/p1785474925692849?thread_ts=1784752825.095419&cid=C0FPKQ6RM), follow-up discussion
Relevant quote: "La idea de defaultear a @NotNull es que nos fuerce a pensar en las invariantes, y escribir mejor código, safe by default.. no en llenar todo de @Nullables y preconditions."

- The non-null default is meant to force thinking about invariants, not to be satisfied
  mechanically: a change that blankets code with `@Nullable` annotations and call-site
  `checkNotNull`s is a smell — prefer designs where the safe thing is the default
- For a field that is legitimately null only during part of an entity's lifecycle, before
  annotating its getter `@Nullable` ask whether any caller actually handles null. Shapes worth
  suggesting:
  - callers that require the value: a dedicated non-null accessor with the precondition embedded
    (e.g. `requireFundingOutput()`), instead of repeating `checkNotNull` at every call site
  - if no caller legitimately handles null, don't expose the nullable getter at all — only the
    requiring accessor
  - callers that must branch on presence: a predicate (e.g. `isFunded()`)
- These shapes are directional, not a settled playbook — the thread deliberately stopped short of
  one. In review, suggest them; don't demand them

## Json DTOs
Source: codebase pattern
Validated against codebase:
- [`JsonDto.java` in `service/`](service/src/main/java/io/muun/service/jackson/JsonDto.java)

- Jackson DTOs in `clients/` and backend services use `@JsonDto`
  (`io.muun.service.jackson.JsonDto`) instead of spelling out the standard pair
  `@JsonInclude(JsonInclude.Include.NON_NULL)` + `@JsonIgnoreProperties(ignoreUnknown = true)`.
  Flag DTOs that write the pair out. DTOs needing different Jackson settings (only one of the
  two, other include modes, `ignoreUnknown = false`) keep their explicit annotations —
  `@JsonDto` is only a shorthand for the exact standard pair.
- DTOs in `common/` use the explicit annotation pair directly (`common/` cannot see `service/`).
- `@JsonDto` classes need no `@SuppressWarnings("NullAway.Init")`: NullAway exempts them via
  `ExternalInitAnnotations` (Jackson populates the fields when parsing the payload). Fields that
  are genuinely optional on the wire must still be annotated `@Nullable`.
- The exemption only applies to classes carrying the annotation directly — a nested DTO class
  needs its own `@JsonDto` (only if it uses the exact standard pair, per the first rule).

## Applications
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Applications"

- Periodic actions registered before resources
- Endpoint interfaces end with `Service`

## Loops
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Loops"
Relevant quote: "Prefer traditional for each instead of .forEach unless the body will only have one line."

- Prefer traditional `for (final var x : list)` over `list.forEach(...)` unless body is a single line (e.g. a method reference)

## Chaining
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Misc"

- One thing per line in chained calls:
```java
LndMissionControlState.builder()
    .state(myMap)
    .build();
```

## Misc
Source: Notion ["Java style-conventions guide"](https://www.notion.so/c55efc19d00d48f586bd8d4cb59d6e6b), section "Misc"

- Avoid `this` unless ambiguous
- Avoid static imports (allowed in tests)
- No unnecessary parentheses (unless non-obvious precedence)
- No more than one line break as separator
