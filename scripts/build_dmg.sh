#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="${APP_NAME:-WallpaperEngineMac}"
APP_PATH="${APP_PATH:-$ROOT_DIR/build/out/$APP_NAME.app}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/build/dist}"
DMG_NAME="${DMG_NAME:-$APP_NAME}"
DMG_PATH="$OUT_DIR/$DMG_NAME.dmg"
VOLUME_NAME="$APP_NAME"

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: App not found at: $APP_PATH" >&2
  echo "Run first: scripts/build_release_app.sh" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

# Create a temporary directory for the DMG contents
STAGING_DIR=$(mktemp -d)
trap 'rm -rf "$STAGING_DIR"' EXIT

echo "==> Preparing DMG contents"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# Remove any existing DMG
rm -f "$DMG_PATH"

echo "==> Creating DMG"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_PATH"

echo "==> Done:"
echo "$DMG_PATH"
echo ""
echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
