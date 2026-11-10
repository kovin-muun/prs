# Claude security review scripts

A copy of the scripts from
[anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review)
at commit `0c6a49f1fa56a1d472575da86a94dbc1edb78eda` (main, 2026-02-11), with these changes.
`.github/workflows/security-review.yml` runs them.

Only the files that the workflow runs are here. The upstream tests, evals and `action.yml` are not.

## Compare with upstream

```bash
git clone https://github.com/anthropics/claude-code-security-review "$TMPDIR/upstream"
git -C "$TMPDIR/upstream" checkout 0c6a49f1fa56a1d472575da86a94dbc1edb78eda
git diff --no-index "$TMPDIR/upstream/claudecode" .github/security-review/claudecode
git diff --no-index "$TMPDIR/upstream/scripts/comment-pr-findings.js" \
  .github/security-review/scripts/comment-pr-findings.js
```

`git log -- .github/security-review` shows each change on its own commit.

To update to a new upstream commit, copy its files over these, keep the changes, and update
the commit in this file.

## Changes from upstream

- `claude_api_client.py`: the filter checks API access with `claude-haiku-5-5`. Upstream uses a
  retired model, so the check fails and the filter turns itself off.
- `comment-pr-findings.js`: no 👍 and 👎 reactions on the comments.
- `github_action_audit.py`: when the diff is over 500 KB, lockfile changes leave it. On a large
  dependency change they push the prompt over the model's context.
- `github_action_audit.py`: the scan stops at `MAX_BUDGET_USD` and runs once, without retries.
- `github_action_audit.py`: a scan that stops with an error result or unparsable output reports
  Claude Code's output. Upstream retries those once, and with no retries it reported only
  "Unexpected error in retry logic".
