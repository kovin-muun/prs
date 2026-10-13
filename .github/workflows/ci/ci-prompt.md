Review this pull request by following the review workflow in the <review-workflow>
block of your system prompt.
This is a PR review. Ignore all Local mode instructions in the review workflow.
The guidance source files for the detected languages are pre-loaded in the
<review-guidance> block of your system prompt — use them directly and skip the
file reads in Step 2.

Provide detailed feedback using inline comments for specific issues.

IMPORTANT:
  1. use `gh pr diff` as the source of truth for what changed in this PR. Do NOT use
     `git diff origin/master..HEAD` (two-dot) — it includes unrelated changes merged to master
     after the branch diverged. If you need a local git diff, always use three-dot syntax:
     `git diff origin/master...HEAD` (which shows only changes the branch introduced).
  2. don't be sycophantic in the feedback and rather address issues that need attention in a straight direct manner.
  3. only provide feedback about issues that need to be addressed, not feedback about a work well done.
  4. don't repeat feedback already given for previous pushes in this PR.
  5. if you don't have new things to say, then don't post any new comment.
  6. only post findings you are confident about. If you find yourself hedging (e.g. "likely",
     "in practice", "might", "could potentially"), treat that as a signal that you are not sure
     enough to post. Either verify the claim first or drop the finding.
  7. before posting, deduplicate findings: if the same root cause appears under multiple categories, post it once
     under the most severe category and mention the secondary impact inline.
  8. when placing an inline comment, target the exact line that contains the problem — not
     the enclosing block header, function signature, or nearby context line. This is critical
     when using GitHub suggestion blocks, because GitHub replaces the line the comment is attached
     to. A suggestion on the wrong line produces a nonsensical replacement.

BUDGET:
  The budget for this review is ${MAX_BUDGET_USD}. Keep context small to stay within budget:
  - Use the diff as the primary review surface. Do not read every changed file — only read a
    file when a specific finding needs context the diff hunks do not provide (e.g., verifying
    an import, checking if a method is used elsewhere in the same file).
  - When you do read a file, read only the relevant range. For files over 500 lines, read the
    changed hunks ± 50 lines of context instead of the full file.
  - Only read files outside the PR diff when you have a concrete finding that requires verification.
    Do not read files speculatively or to "understand context."
  - Avoid broad codebase greps for style sampling. Judge style from the diff and the pre-loaded guidance.
