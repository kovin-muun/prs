# Muun Deployment & Database Migration Standards

Source: Notion ["Our practices"](https://www.notion.so/b125a87b52de4906bd6f99670e3e635f), ["Muun-specific best practices"](https://www.notion.so/5e0f40684a304dc097298433b5a8917f) + PR patterns.

Validated against codebase:
- [`forwarder/.../migrations.xml` @ 453eec62](https://github.com/muun/muun/blob/453eec62b191da92a203628dad1f392c36935033/forwarder/src/main/resources/migrations.xml)
- [`houston/.../migrations.xml` @ 7224c4ee](https://github.com/muun/muun/blob/7224c4eefcf9c3457a6f2b6002e5b792039f8c7a/houston/src/main/resources/migrations.xml)

## Deployment Model
Source: Notion ["Our practices"](https://www.notion.so/b125a87b52de4906bd6f99670e3e635f), sections "Our production mindset" and "CD"

- Trunk-based development with Bors for merges
- Backend services auto-deploy to production on merge to master
- No guaranteed deploy order between services
- Task is done when providing value in production, not when PR merges

## Deployment Safety Checks
Source: Notion ["Our practices"](https://www.notion.so/b125a87b52de4906bd6f99670e3e635f), section "CD"
Relevant quote: "if you add a required field to a request, nothing guarantees that the callers will be deployed first. If this happens, callers will error out due to a missing required field. This is easy to solve in one of two ways: 1. Making the field optional and adding a sane default. 2. Splitting the PR in two: first, add the field to the callers, then in the receiver."
Relevant quote: "It might be necessary to split migrations into several forward/backward compatible steps to avoid downtime. ... To do so, the first PR adds the new column as nullable, backfills it, and makes the service start populating it via code. The second PR makes the code use the new column only, makes it non-null, and deletes the old one. This two-step process ensures that if a mistake is made, the service can still be rolled back without data loss or downtime."

### Out-of-order deployment
Services may deploy in any order. Changes spanning multiple services must handle this:
- **New required field in a request**: make it optional with a sane default, OR split into two PRs (callers first, receiver second)
- **API changes**: backward-compatible first, then forward-only in a follow-up
- Ask: "If this service deploys before/after its dependencies, will things break?"

### Rollback safety
- Changes must be safely rollbackable
- Ask: "If we need to roll back this deploy, what happens?"
- Data written by new code should be readable by old code (or at least not cause errors)

### Startup time
- Changes should not adversely affect service startup time
- Large initializations should be lazy or async

## Database Migrations (Liquibase)
Source: Notion ["Muun-specific best practices"](https://www.notion.so/5e0f40684a304dc097298433b5a8917f), section "Databases"
Relevant quote: "We try to make all migrations rollbackable. Some operations are auto-rollbackable, like `<addColumn>`, but others, like `<sql>`, are not. We enclose those which are not between `<rollback>` tags."
Relevant quote: "Table names should be plural nouns and should be snake_case. Column names should be camelCase. An important exception for this is houston: columns there are snake_case. Index names should be named `idx_$tablename_$columnname`. Foreign keys in a table should be named `fk_$childtable_$columnname`."

### Naming Conventions
- Tables: plural snake_case (`transaction_inputs`)
- Columns: camelCase (`outputIndex`) — **exception: houston uses snake_case columns**
- Index: `idx_$tablename_$columnname` (preserving original casing)
- Composite index: `idx_$tablename_$col1_$col2`
- Unique constraint: `unique_$tablename_$col1_$col2`
- Foreign key: `fk_$childtable_$columnname`

### Migration Safety
- All migrations should be rollbackable
- Auto-rollbackable ops (e.g. `<addColumn>`): no extra work needed
- Non-auto-rollbackable ops (e.g. `<sql>`): enclose in `<rollback>` tags
- Adding a non-null column requires multi-step approach:
  1. PR 1: Add column as nullable, backfill data, start populating via code
  2. PR 2: Switch code to use new column only, make it non-null, delete old column
- Reference: [Braintree downtime-less migration guide](https://gist.github.com/jcoleman/1e6ad1bf8de454c166da94b67537758b)

### XML Formatting
Source: Notion ["Muun-specific best practices"](https://www.notion.so/5e0f40684a304dc097298433b5a8917f), section "XML"
Relevant quote: "When a tag takes more than one line, each attribute should have its own line."

- Multi-line tags: each attribute on its own line
- Prefer short-hand `<column ... />` over `<column ...> </column>`

### Hibernate Queries
Source: codebase pattern
Validated against codebase:
- [`IncomingHtlcRepository.java` @ 128bb904](https://github.com/muun/muun/blob/128bb904652eeb29a43c52bbd6b220b08cdf72ac/forwarder/src/main/java/io/muun/forwarder/data/repository/IncomingHtlcRepository.java)

- Raw queries formatted per Hibernate doc
- `.setComment("ClassName#methodName")` on NativeQuery for Honeycomb tracing

## PR & Commit Conventions
Source: Notion ["Muun-specific best practices"](https://www.notion.so/5e0f40684a304dc097298433b5a8917f), section "PRs and commit structure"
Relevant quote: "All commit messages should be prefixed with the service name(s) it affects. ... `multi: rest-of-the-commit-message` (when changes affect so many services that it is not practical to enumerate them all). The same applies to PR and issue titles as well."
Relevant quote: "Commit messages should be written in imperative, present tense."
Relevant quote: "It is customary to rearrange the commit history of a branch before asking for a review, so that changes are ordered in a way that is easier to understand for the reviewer."

- Commit prefix: service name(s) — `funder: message`, `funder, syncer: message`. Use `multi: message` only when changes affect so many services that it is not practical to enumerate them all. The same applies to PR and issue titles.
- Imperative present tense: `syncer: update foo` (not "updating" or "updated")
- Max 100 chars per commit message line
- PRs tagged with service-specific labels (`syncer`, `mempool`, etc.)
- Special labels: `do-not-merge`, `wip`, `on-hodl`
- Rearrange commit history before review — changes ordered as a story for the reviewer
- Reference the source (Zendesk ticket, GitHub issue, Slack thread, Notion spec, incident report)

## Database Naming Quick Reference
Source: Notion ["Muun-specific best practices"](https://www.notion.so/5e0f40684a304dc097298433b5a8917f), section "Databases"

This summarizes the full naming rules in the migration section above for quick review use:

- Table names: plural snake_case (`transaction_inputs`)
- Column names: camelCase (`outputIndex`) — **exception: houston uses snake_case**
- Index: `idx_$tablename_$columnname`
- Unique constraint: `unique_$tablename_$col1_$col2`
- Foreign key: `fk_$childtable_$columnname`

## What Reviewers Check
- Can changes be safely rolled back?
- Are migrations rollbackable? Non-auto-rollbackable ops have `<rollback>` tags?
- Does a non-null column addition follow the two-step approach?
- Are multi-service changes safe for out-of-order deployment?
- Is startup time unaffected?
- Do commits follow the service prefix convention and imperative tense?
- Is the PR properly scoped and labeled?
- Do table/column/index names follow naming conventions (including the houston snake_case exception)?
- Does migration XML use the multi-line attribute format for multi-line tags?
