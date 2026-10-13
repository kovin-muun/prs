Review this pull request by following the review workflow in the <review-workflow>
block above.
This is a PR review. Ignore all Local mode instructions in the review workflow.
The guidance source files for the detected languages are pre-loaded in the
<review-guidance> block above — use them directly and skip the file reads in Step 2.

INPUTS:
  You run in a read-only sandbox with no network access, so `gh` and `git fetch` do not work.
  Use these inputs instead of the commands in Steps 1, 3 and 6:
  - the current directory: a checkout of the PR head commit. Read changed files here. Do not
    create a worktree.
  - `../.codex-review/pr.json`: PR title, body, URL, base and head refs, and commits.
  - `../.codex-review/pr.diff`: the output of `gh pr diff`, with each added or context line
    prefixed by its line number in the new file. It is the source of truth for what changed in
    this PR.
  - `../.codex-review/review-comments.json`: inline review comments already on the PR. A
    comment with a `start_line` covers the lines from `start_line` to `line`.
  - `../.codex-review/issue-comments.json`: top-level comments already on the PR.

OUTPUT:
  Ignore the output format in Step 5. Return JSON that matches the output schema:
  - `comments`: new inline comments.
    - `path` is relative to the repository root.
    - `line` is a line number from `pr.diff`. Never count diff lines yourself. It must be an
      added or context line inside a hunk, or GitHub rejects the comment.
    - `body` holds one finding, with the severity, category, description and convention from
      the Step 5 finding format. A GitHub ```suggestion block replaces exactly the line in
      `line`.
  - `replies`: replies to existing inline comments. `comment_id` must be the `id` of the first
    comment in the thread (the one whose `in_reply_to_id` is null).
  Return empty arrays when you have nothing new to say.

OTHER REVIEWERS:
  Claude reviews this PR before you. Its comments come from `claude[bot]`. Your own earlier
  comments come from `github-actions[bot]` and start with `**Codex:**`.
  1. do not post a finding that Claude or your earlier comments already raised.
  2. reply to a Claude comment only when you disagree with it or have relevant information to
     add. Say why, concretely. Do not reply only to agree.
  3. do not reply to a thread that already has your reply, unless the code changed since then.

IMPORTANT:
  1. don't be sycophantic in the feedback and rather address issues that need attention in a straight direct manner.
  2. only provide feedback about issues that need to be addressed, not feedback about a work well done.
  3. only post findings you are confident about. If you find yourself hedging (e.g. "likely",
     "in practice", "might", "could potentially"), treat that as a signal that you are not sure
     enough to post. Either verify the claim first or drop the finding.
  4. before posting, deduplicate findings: if the same root cause appears under multiple categories, post it once
     under the most severe category and mention the secondary impact inline.
  5. when placing an inline comment, target the exact line that contains the problem — not
     the enclosing block header, function signature, or nearby context line. This is critical
     when using GitHub suggestion blocks, because GitHub replaces the line the comment is attached
     to. A suggestion on the wrong line produces a nonsensical replacement.

CONTEXT:
  Keep context small:
  - Use the diff as the primary review surface. Do not read every changed file — only read a
    file when a specific finding needs context the diff hunks do not provide (e.g., verifying
    an import, checking if a method is used elsewhere in the same file).
  - When you do read a file, read only the relevant range. For files over 500 lines, read the
    changed hunks ± 50 lines of context instead of the full file.
  - Only read files outside the PR diff when you have a concrete finding that requires verification.
    Do not read files speculatively or to "understand context."
  - Avoid broad codebase greps for style sampling. Judge style from the diff and the pre-loaded guidance.
