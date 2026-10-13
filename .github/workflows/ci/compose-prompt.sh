#!/usr/bin/env bash
# Assemble the review prompt for the CI workflow.
# The review workflow and pre-loaded guidance go into a system-prompt append
# file: it is byte-identical across runs of the same language set, so with a
# stable system prompt it stays prompt-cached across CI runs. The per-PR user
# prompt (stdout) carries only the PR reference and the review instructions.
#
# Usage: compose-prompt.sh <pr-number> <repo> <max-budget-usd> <system-append-file> [<prompt-template>]
# <prompt-template> is a file in this directory; it defaults to ci-prompt.md.
# Requires GH_TOKEN in environment (for gh pr diff).
set -euo pipefail

PR="$1"
REPO="$2"
export MAX_BUDGET_USD="$3"
SYSTEM_FILE="$4"
PROMPT_TEMPLATE="${5:-ci-prompt.md}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REVIEW_DIR="$SCRIPT_DIR/../../review"

{
  echo "<review-workflow>"
  cat "$REVIEW_DIR/muun-review.md"
  echo "</review-workflow>"
  echo ""
  echo "<review-guidance>"
  bash "$SCRIPT_DIR/preload-guidance.sh" "$PR"
  echo "</review-guidance>"
} > "$SYSTEM_FILE"

echo "REPO: $REPO"
echo "PR NUMBER: $PR"
echo ""

# Static review instructions (substitutes ${MAX_BUDGET_USD})
envsubst '${MAX_BUDGET_USD}' < "$SCRIPT_DIR/$PROMPT_TEMPLATE"
