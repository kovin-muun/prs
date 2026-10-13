---
name: muun-review
description: Review a Muun PR or local branch (Java, Kotlin, Go, Swift) against Muun conventions. Numeric arg is a PR number; non-numeric or empty arg is a local review vs. a base branch (default `master`). Use when asked to review a PR, review the current branch, or check changes against Muun conventions.
argument-hint: <pr-number> | [<base-branch>]
user-invocable: true
allowed-tools: Bash(gh pr view *), Bash(gh pr diff *), Bash(git fetch *), Bash(git worktree *), Bash(git show *), Bash(git update-ref *), Bash(git diff *), Bash(git log *), Bash(git rev-parse *), Read, Glob, Grep
---

# Muun Review Workflow

This document describes how to review a Muun change against Muun conventions, either from a merged/open PR or from the local branch before a PR exists.

Two modes, determined from `$ARGUMENTS`:

- **PR mode** — `$ARGUMENTS` matches `^\d+$`. Treat it as a PR number; fetch and review it from GitHub.
- **Local mode** — otherwise. Review the current branch against a base. `<base>` = `$ARGUMENTS` if non-empty, else `master`.

Resolve the mode and the resolved value (`<pr-number>` or `<base>`) **before Step 1**. Every subsequent step references these placeholders.

Scope (both modes):

- human-readable review output only
- no GitHub posting
- no inline comments

Supported languages:
- **Java**: `.java`, `.xml` and `.gradle` for backend and config.
- **Kotlin**: `.kt` for Apollo and Toolkit.
- **Go**: `.go` for Libwallet and other small services.
- **Swift**: `.swift` for Falcon (iOS).

Apply each ruleset only to its own files, and ignore non-supported files.

Falcon project and support files (`project.pbxproj`, `Podfile.lock`, `Package.resolved`,
`Podfile`, `*.strings`, `*.xcassets` contents, `*.plist`) are not reviewed line-by-line, but are
checked for commit hygiene and localization completeness (Step 4, Swift / Falcon categories).
Ignore generated Swift files (`Strings+Generated.swift` and other SwiftGen output, `*.pb.swift`,
protobuf output under `core/Protobuf/`) except to verify they were regenerated when their inputs
changed.

Files under `cards/` are out of scope regardless of extension: MuunCard V3 JavaCard firmware and
its Go tooling have their own dedicated skill, `/cards-review`
(`.claude/skills/cards-review/SKILL.md`), because the Dropwizard-shaped Java testing/
observability/deployment/architecture rules and the general Go guidance don't fit hardware
firmware or its dual-client tooling. If a reviewed PR or branch touches `cards/` files, skip them
and note in the output that they were deferred to `/cards-review`. If `cards/` files are the only
changes, produce no findings for this workflow.

## Step 1: Gather Inputs

The file list drives language detection in Step 2. Commit messages (both modes) and PR body (PR mode only) drive the Reviewability category in Step 4.

### PR mode

Fetch PR metadata, the diff, and the PR head ref:

```bash
gh pr view <pr-number> --json title,body,url,baseRefName,headRefName,headRefOid,files,commits
gh pr diff <pr-number>
git fetch origin pull/<pr-number>/head:refs/remotes/origin/pr-<pr-number> --force
git show --stat --format='%h %s' <oid>   # per commit: file list for prefix and scoping checks
```

Use the PR title, body, URL, file list, commit messages, and diff as review inputs.

Rules:

- name the ref predictably as `origin/pr-<pr-number>`
- do not assume the local working tree matches the PR branch
- prefer `git fetch` over `gh api` file reads — it only updates local git refs and avoids GitHub write surfaces
- keep using `gh pr view` and `gh pr diff` for metadata and diff context
- use the plain (collapsed) `gh pr diff` as the only diff input — never `gh pr diff --patch`. On a
  rebased-and-amended branch the patch series repeats file content, surfaces issues that later
  commits in the same PR already fix, and its hunk positions don't match the head diff.
- layer the commit inputs by cost: commit messages come from `gh pr view`; per-commit file lists
  come from `git show --stat` (run it for each commit oid after the fetch); read a single commit's
  full diff (`git show <oid>`) only when its message or stats raise a concrete scoping concern

### Local mode

Read the diff, file list, and commits from the current branch relative to `origin/<base>`. Refresh the remote ref first so the comparison is against the current tip of `<base>` on origin, not a stale local ref:

```bash
git fetch origin <base>                                           # refresh origin/<base>
git rev-parse --abbrev-ref HEAD                                   # branch name for the output header
git rev-parse --short HEAD                                        # SHA to name the worktree in Step 3
git diff --name-only origin/<base>...HEAD                         # file list → drives Step 2
git diff origin/<base>...HEAD                                     # diff for review
git log origin/<base>..HEAD --pretty=format:'%h %s%n%b%n---'      # commits for reviewability
```

Use the branch name, HEAD SHA, file list, commit messages, and diff as review inputs. There is no PR body in this mode.

Rules:

- three-dot `origin/<base>...HEAD` gives the changes on the branch since it diverged from the remote tip of `<base>` — this matches what a PR diff would compute against on the server
- compare against `origin/<base>`, not local `<base>` — the local ref can be stale (never pulled, committed to directly, or origin was force-pushed) and would silently drift the review scope
- review only committed changes on HEAD; do not include uncommitted working-tree changes

## Step 2: Detect Languages And Load Guidance

Exclude any file under `cards/` first (see Scope above) — it never counts toward the
Java/Kotlin/Go/Swift detection below, regardless of extension.

From the changed file extensions, determine which supported languages the PR touches, and read
**only** the matching convention files before reviewing:

- **Java backend** (`.java`, `.xml`, `.gradle`):
  - `.github/review/sources/java/review-java-style.md`
  - `.github/review/sources/java/review-testing.md`
  - `.github/review/sources/java/review-observability.md`
  - `.github/review/sources/java/review-deployment.md`
  - `.github/review/sources/java/review-architecture.md`

- **Kotlin** (`.kt`):
  - `.github/review/sources/kotlin/review-kotlin-style.md`
  - `.github/review/sources/java/review-java-style.md` (the Kotlin guide extends the Java style guide)

  Do **not** apply the Java testing/observability/deployment/architecture rules to Kotlin.
  Toolkit and Apollo Kotlin don't follow those conventions.

- **Go** (`.go`):
  - `.github/review/sources/go/review-go-style.md`
  - `.github/review/sources/go/review-libwallet-conventions.md` **ONLY** when a changed file is under `libwallet/` 

- **Swift** (`.swift`):
  - `.github/review/sources/swift/review-swift-falcon.md`

## Step 3: Inspect Files And Commits Locally

For most reviews, use a worktree so files can be read and navigated directly. The worktree is created inside the project directory, so no extra permissions are needed to read from it.

### PR mode

```bash
# Remove stale worktree from a previous review of this PR, if one exists:
git worktree remove --force .claude/worktrees/pr-<pr-number> 2>/dev/null || true
git worktree add .claude/worktrees/pr-<pr-number> origin/pr-<pr-number>
```

Use `git show origin/pr-<pr-number>:path/to/file.ext` for single-file spot checks only.

### Local mode

Anchor the worktree to the HEAD SHA (from Step 1), not to the branch name, so the review is stable if the branch moves during the session:

```bash
# Remove stale worktree from a previous local review at the same SHA, if one exists:
git worktree remove --force .claude/worktrees/local-review-<sha-short> 2>/dev/null || true
git worktree add .claude/worktrees/local-review-<sha-short> HEAD
```

Use `git show HEAD:path/to/file.ext` for single-file spot checks only.

### Shared rules (both modes)

- read the full contents of changed files in supported languages
- read changed config, build, and migration files when present
- only read files outside the diff when you have a concrete finding that requires verification — do not read surrounding code speculatively or to "understand context". Two Falcon-specific exceptions where a targeted look outside the diff **is** expected:
  - when a change adds user-facing strings, check both `en.lproj` and `es.lproj` got entries
  - when a change adds a formatter/helper/VC behavior, grep for an existing equivalent before
    flagging (or dismissing) a DRY finding
- ignore generated and vendored files: `*.pb.go` and the Go build/vendor dirs (`.build/`, `vendor/`, `librs/`); for Falcon, SwiftGen output, `*.pb.swift`, and `Pods/`
- if a file was deleted, review it from the diff and surrounding context
- use the worktree as the main inspection surface, not repeated `git show` calls

## Step 4: Review

Apply all the following review categories. For each finding, determine:

- **Severity**: `BLOCKER`, `SUGGESTION`, or `NIT`
- **Category**: `style`, `testing`, `observability`, `deployment`, `architecture`, `functionality`, or `reviewability`

Some category definitions differ between programming languages and or specific projects.

### Categories common to all languages

#### Reviewability

- does the PR body state the problem clearly? *(PR mode only — skip in local mode)*
- do the commits use service prefixes such as `houston:` or `swapper, forwarder:`?
- are commit messages imperative present tense?
- is the change appropriately scoped, or is it mixing unrelated changes?
- do the commits tell a readable story?

#### Functionality

- does the code do what it claims?
- are there obvious logic bugs or edge-case issues?
- are nullability and empty-collection cases handled clearly?
- are nullable values documented when non-obvious?

### Java & Backend categories

#### Code Style

Use `.github/review/sources/java/review-java-style.md`.
Apply the checklist in the `## What Reviewers Check` section of that file.

#### Architecture And Design

Use `.github/review/sources/java/review-architecture.md`.
Apply the checklist in the `## What Reviewers Check` section of that file.

#### Testing

Use `.github/review/sources/java/review-testing.md`.
Apply the checklist in the `## What Reviewers Check` section of that file.

#### Observability

Use `.github/review/sources/java/review-observability.md`.
Apply the checklist in the `## What Reviewers Check` section of that file.

#### Deployment Safety

Use `.github/review/sources/java/review-deployment.md`.
Apply the checklist in the `## What Reviewers Check` section of that file. This includes database migration conventions.

### Go categories

**Code Style**, **Testing** and **Observability** categories should apply the checklists found on
the relevant sections in `.github/review/sources/go/review-go-style.md`, also taking into account the
`## What Reviewers Check` section. 

In case the file being reviewed is under `libwallet/` then also apply the
**Architecture And Design**, **Testing** and **Observability** categories using the relevant sections found on
`.github/review/sources/go/review-libwallet-conventions.md`, also taking into account the `## What Reviewers Check` section.

Rules and conventions marked as WIP should be enforced softly, as they are still being defined.

### Kotlin categories

Apply all category rules found on `.github/review/sources/kotlin/review-kotlin-style.md` or
`.github/review/sources/java/review-java-style.md`.
DO NOT apply the Java backend testing/observability/deployment/architecture rules.

### Swift / Falcon categories

Apply only to `.swift` files under `falcon/`, plus the Falcon project and support files named in
the Scope section.

Use `.github/review/sources/swift/review-swift-falcon.md`. Apply every numbered section as a
category, plus the "Hard conventions" section (localization, analytics, DI), and run the
`## What Reviewers Check` checklist at the end to catch anything missed. For Falcon findings the
category set extends to: `design-system`, `hygiene`, `error-handling`, `concurrency`, `reuse`,
`naming`, `lifecycle`, `dead-code`, `docs`, and `cross-platform`, in addition to the common
categories.

Severity calibration:

- Violations of hard conventions from `falcon/CLAUDE.md` (hardcoded strings/colors, closures
  instead of delegates, domain models in VCs, string-form analytics) are `BLOCKER` or
  `SUGGESTION` depending on blast radius.
- Frequency-derived findings (naming, lifecycle grouping, token consistency) are usually
  `SUGGESTION` or `NIT` — phrase them as the team does, as questions when the right answer
  depends on context.

Falcon additions to the common categories:

- **Reviewability**: do the commits use the `falcon:` prefix (`falcon,libwallet:` for
  cross-module)? Do new `.swift` files include their `.pbxproj` change in the same commit?
- **Functionality**: are optionals and empty-collection cases handled clearly, and force-unwraps
  justified? What happens on back navigation, backgrounding, and re-entry?

## Step 5: Output

Format findings as follows, sorted by severity. Within each severity group, order findings by file path.

Header depends on mode. Everything below the header is identical in both modes.

**PR mode**:

```text
## Code Review: [PR title]
**PR**: [url]
```

**Local mode**:

```text
## Code Review: <branch>
**Base**: <base>  •  **HEAD**: <sha-short>
```

Body (both modes):

```text
### Blockers
> These must be fixed before merging.

**[BLOCKER | category]** `path/file.ext:line`
Description of the issue in the context of this PR.
**Convention** `[upstream source]`
> "Short quoted rule or cited excerpt."

---

### Suggestions
> Strongly recommended improvements.

**[SUGGESTION | category]** `path/file.ext:line`
Description of the issue in the context of this PR.
**Convention** `[upstream source]`
> "Short quoted rule or cited excerpt."

---

### Nits
> Minor style or preference items.

**[NIT | category]** `path/file.ext:line`
Description of the issue in the context of this PR.
**Convention** `[upstream source]`
> "Short quoted rule or cited excerpt."

---

### What looks good
Brief notes on patterns that match Muun conventions well. Omit this section if there is nothing specific to call out.
```

If there are no findings in a severity category, omit that section.

## Step 6: Clean Up

Remove the temporary worktree when you are done.

### PR mode

```bash
git worktree remove .claude/worktrees/pr-<pr-number>
```

If you do not expect to revisit the PR soon, you can also remove the fetched ref:

```bash
git update-ref -d refs/remotes/origin/pr-<pr-number>
```

### Local mode

```bash
git worktree remove .claude/worktrees/local-review-<sha-short>
```

No ref to clean up.

## Important Notes

- Be specific. Every finding should reference a concrete file and line.
- Be Muun-specific. If a finding cannot point to a Muun convention, reconsider whether it belongs.
- Prefer codebase-consistent judgments over generic best practices.
- Use the local guidance files to find the real upstream source, but do not cite the local markdown file as if it were the source.
- For doc-derived rules, cite the Notion page or section named in the local guidance file.
- For codebase-derived rules, cite the concrete `Validated against codebase` path from the local guidance file.
- If the local guidance file does not carry an exact quote for a rule, cite the upstream source and summarize the rule accurately.
- Convention violations are in scope regardless of linter coverage.
- For Falcon rules derived from `falcon/CLAUDE.md`, cite the section named in the guidance file;
  for PR-pattern-derived rules, cite the PR number(s) from the guidance file.
- For Falcon findings, match the team's review voice: when the finding is a judgment call rather
  than a hard rule, phrase it as a question.

