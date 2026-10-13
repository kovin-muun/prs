#!/usr/bin/env bash
# Post the review that Codex returned as JSON (see codex-review-schema.json).
# GitHub rejects a comment on a line outside the diff. Such a comment is logged
# and skipped, so it does not drop the rest of the review.
#
# Usage: post-codex-review.sh <pr-number> <repo> <head-sha> <review-json>
# Requires GH_TOKEN in environment.
set -euo pipefail

PR="$1"
REPO="$2"
HEAD_SHA="$3"
REVIEW="$4"

# Codex posts as github-actions[bot]; the prefix tells readers (and the next
# Codex run) which comments are from Codex.
PREFIX='**Codex:** '

while IFS= read -r comment; do
  path=$(jq -r .path <<<"$comment")
  line=$(jq -r .line <<<"$comment")
  body=$(jq -r .body <<<"$comment")
  if ! gh api "repos/$REPO/pulls/$PR/comments" --silent \
      -f commit_id="$HEAD_SHA" -f side=RIGHT -f path="$path" -F line="$line" \
      -f body="$PREFIX$body"; then
    echo "::warning::Could not post comment on $path:$line"
    echo "$body"
  fi
done < <(jq -c '.comments[]' "$REVIEW")

while IFS= read -r reply; do
  id=$(jq -r .comment_id <<<"$reply")
  body=$(jq -r .body <<<"$reply")
  if ! gh api "repos/$REPO/pulls/$PR/comments/$id/replies" --silent \
      -f body="$PREFIX$body"; then
    echo "::warning::Could not reply to comment $id"
    echo "$body"
  fi
done < <(jq -c '.replies[]' "$REVIEW")
