#!/usr/bin/env bash
# Read a unified diff on stdin and prefix each added or context line with its
# line number in the new file. Removed lines get a blank number. The reviewers
# take inline comment line numbers from this output instead of counting lines.
#
# Usage: gh pr diff <pr-number> | number-diff.sh
set -euo pipefail

awk '
  /^diff --git / { in_hunk = 0 }
  /^@@ / {
    match($0, /\+[0-9]+/)
    line = substr($0, RSTART + 1, RLENGTH - 1)
    in_hunk = 1
    print
    next
  }
  in_hunk && /^-/ { printf "%6s %s\n", "", $0; next }
  in_hunk && /^[+ ]/ { printf "%6d %s\n", line++, $0; next }
  { print }
'
