#!/bin/zsh

set -e

# ---------------------------------------------------------------------------
# publish-mac-arm.sh — Build and publish a signed macOS ARM release
#
# Reads secrets from .env.publish (GH_TOKEN, APPLE_*, SENTRY_DSN, POSTHOG_*).
# Clones a fresh shallow copy of the repo to guarantee a clean build, then
# runs the electron-builder pipeline with code signing and notarization.
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source secrets — must exist alongside the repo root
if [ ! -f "$REPO_ROOT/.env.publish" ]; then
  echo "Missing .env.publish — copy .env.example and fill in values."
  exit 1
fi
source "$REPO_ROOT/.env.publish"

# Validate that critical env vars are set
for var in GH_TOKEN APPLE_ID APPLE_TEAM_ID APPLE_APP_SPECIFIC_PASSWORD; do
  if [ -z "${(P)var}" ]; then
    echo "Required env var $var is not set in .env.publish"
    exit 1
  fi
done

# Create a clean build directory next to the repo
BUILD_DIR="$REPO_ROOT/../build_publish"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Clone the current branch at HEAD (shallow) for a clean build
CURRENT_BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)
REMOTE_URL=$(git -C "$REPO_ROOT" remote get-url origin)
echo "Cloning $REMOTE_URL ($CURRENT_BRANCH) into $BUILD_DIR/books..."
git clone "$REMOTE_URL" --branch "$CURRENT_BRANCH" --depth 1 "$BUILD_DIR/books"
cd "$BUILD_DIR/books"

# Install dependencies
yarn install

# Export env vars for electron-builder and the build script
export GH_TOKEN
export CSC_IDENTITY_AUTO_DISCOVERY=true
export APPLE_ID
export APPLE_TEAM_ID
export APPLE_APP_SPECIFIC_PASSWORD
export SENTRY_DSN
export POSTHOG_KEY
export POSTHOG_HOST

# Build and publish
yarn build --mac --publish=always

echo ""
echo "Done — check GitHub Releases for the draft."
