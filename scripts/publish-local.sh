#!/bin/zsh

set -e

# ---------------------------------------------------------------------------
# publish-local.sh — Build a signed macOS ARM app for local distribution
#
# Builds directly in the working tree (no clone). Produces a signed and
# notarized .dmg in dist_electron/bundled/ but does NOT upload to GitHub.
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source secrets
if [ ! -f "$REPO_ROOT/.env.publish" ]; then
  echo "Missing .env.publish — copy .env.example and fill in values."
  exit 1
fi
source "$REPO_ROOT/.env.publish"

# Validate Apple signing env vars (GH_TOKEN not required for local builds)
for var in APPLE_ID APPLE_TEAM_ID APPLE_APP_SPECIFIC_PASSWORD; do
  if [ -z "${(P)var}" ]; then
    echo "Required env var $var is not set in .env.publish"
    exit 1
  fi
done

# Export env vars for electron-builder and the build script
export CSC_IDENTITY_AUTO_DISCOVERY=true
export APPLE_ID
export APPLE_TEAM_ID
export APPLE_APP_SPECIFIC_PASSWORD
export SENTRY_DSN
export POSTHOG_KEY
export POSTHOG_HOST

cd "$REPO_ROOT"

# Build signed app — no GitHub upload
yarn build --mac --publish=never

echo ""
echo "Build complete. Artifacts:"
ls -lh "$REPO_ROOT/dist_electron/bundled/"*.dmg 2>/dev/null || echo "  (no .dmg found — check dist_electron/bundled/)"
