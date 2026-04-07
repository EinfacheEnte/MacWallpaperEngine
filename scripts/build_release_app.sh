#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BUNDLE_ID="${BUNDLE_ID:-com.einfacheente.macwallpaperengine.alpha}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/build/DerivedData}"
CONFIGURATION="${CONFIGURATION:-Release}"
SCHEME="${SCHEME:-WallpaperEngineMac}"

echo "==> Building .app via xcodebuild"
rm -rf "$DERIVED_DATA"

xcodebuild \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED_DATA" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  CODE_SIGNING_ALLOWED=NO \
  build

APP_PATH="$DERIVED_DATA/Build/Products/$CONFIGURATION/$SCHEME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: App not found at: $APP_PATH" >&2
  exit 1
fi

OUT_DIR="$ROOT_DIR/build/out"
mkdir -p "$OUT_DIR"
cp -R "$APP_PATH" "$OUT_DIR/"

echo "==> Output:"
echo "$OUT_DIR/$SCHEME.app"

