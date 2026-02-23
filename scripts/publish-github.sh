#!/bin/zsh

set -e

# ---------------------------------------------------------------------------
# publish-github.sh — Build and publish a signed macOS ARM release to GitHub
#
# Clones a fresh shallow copy from origin (WillNeill/books) into a temp
# directory for a clean-room build, then signs, notarizes, and uploads
# a draft release to GitHub Releases.
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source secrets
if [ ! -f "$REPO_ROOT/.env.publish" ]; then
  echo "Missing .env.publish — copy .env.example and fill in values."
  exit 1
fi
source "$REPO_ROOT/.env.publish"

# Validate all required env vars (including GH_TOKEN for upload)
for var in GH_TOKEN APPLE_ID APPLE_TEAM_ID APPLE_APP_SPECIFIC_PASSWORD; do
  if [ -z "${(P)var}" ]; then
    echo "Required env var $var is not set in .env.publish"
    exit 1
  fi
done

# Resolve origin remote — must point to WillNeill/books
REMOTE_URL=$(git -C "$REPO_ROOT" remote get-url origin)
if [[ "$REMOTE_URL" != *"WillNeill/books"* ]]; then
  echo "Error: origin remote does not point to WillNeill/books"
  echo "  origin = $REMOTE_URL"
  echo "Refusing to publish to an unexpected repo."
  exit 1
fi

# Create a clean build directory next to the repo
BUILD_DIR="$REPO_ROOT/../build_publish"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Clone the current branch at HEAD (shallow) for a clean build
CURRENT_BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)
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

# Build, sign, notarize, and publish to GitHub Releases
yarn build --mac --publish=always

echo ""
echo "Done — check https://github.com/WillNeill/books/releases for the draft."
