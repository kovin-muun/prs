#!/usr/bin/env bash
# Detect languages in a PR and concatenate the matching review guidance files to stdout.
# Called by the CI review workflow to pre-load guidance into the prompt.
#
# Language patterns here must stay in sync with the stack-check step in muun-review.yml
# and Step 2 of muun-review.md.
set -euo pipefail

PR="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCES_DIR="$SCRIPT_DIR/../../review/sources"

# Print a guidance source file with a <!-- source: ... --> annotation so the
# reviewing agent can cite the correct upstream source for each convention.
emit() {
  local path=".github/review/sources/$1"
  echo "<!-- source: $path -->"
  cat "$SOURCES_DIR/$1"
  echo ""
}

# Scan the PR's changed files to decide which language guidance to include.
# cards/ files are excluded — they have a dedicated review skill.
HAS_JAVA=false HAS_KOTLIN=false HAS_GO=false HAS_LIBWALLET_GO=false HAS_SWIFT=false
while IFS= read -r f; do
  case "$f" in cards/*) continue ;; esac
  case "$f" in
    *.java|*.xml|*.gradle) HAS_JAVA=true ;;
    *.kt) HAS_KOTLIN=true ;;
    *.go) HAS_GO=true; case "$f" in libwallet/*) HAS_LIBWALLET_GO=true ;; esac ;;
    *.swift) HAS_SWIFT=true ;;
  esac
done < <(gh pr diff "$PR" --name-only)

# Emit guidance for each detected language. Kotlin extends the Java style
# guide but does not use the Java backend testing/observability/deployment/
# architecture rules.
if [ "$HAS_JAVA" = true ] || [ "$HAS_KOTLIN" = true ]; then
  emit java/review-java-style.md
fi
if [ "$HAS_JAVA" = true ]; then
  emit java/review-testing.md
  emit java/review-observability.md
  emit java/review-deployment.md
  emit java/review-architecture.md
fi
if [ "$HAS_KOTLIN" = true ]; then
  emit kotlin/review-kotlin-style.md
fi
if [ "$HAS_GO" = true ]; then
  emit go/review-go-style.md
fi
if [ "$HAS_LIBWALLET_GO" = true ]; then
  emit go/review-libwallet-conventions.md
fi
if [ "$HAS_SWIFT" = true ]; then
  emit swift/review-swift-falcon.md
fi
