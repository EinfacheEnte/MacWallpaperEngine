#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="${APP_NAME:-WallpaperEngineMac}"
APP_PATH="${APP_PATH:-$ROOT_DIR/build/out/$APP_NAME.app}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/build/dist}"
ZIP_PATH="$OUT_DIR/$APP_NAME.zip"

DEVELOPER_ID_APP="${DEVELOPER_ID_APP:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: App not found at: $APP_PATH" >&2
  echo "Run: scripts/build_release_app.sh" >&2
  exit 1
fi

if [[ -z "$DEVELOPER_ID_APP" ]]; then
  echo "ERROR: Set DEVELOPER_ID_APP to your signing identity." >&2
  echo "Example: DEVELOPER_ID_APP=\"Developer ID Application: Your Name (TEAMID)\"" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "==> Codesigning ($DEVELOPER_ID_APP)"
codesign --force --deep --options runtime --timestamp --sign "$DEVELOPER_ID_APP" "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

if [[ -z "$NOTARY_PROFILE" ]]; then
  echo "ERROR: Set NOTARY_PROFILE to a notarytool keychain profile name." >&2
  echo "Create once with:" >&2
  echo "  xcrun notarytool store-credentials \"PROFILE\" --apple-id \"you@example.com\" --team-id \"TEAMID\" --password \"app-specific-password\"" >&2
  exit 1
fi

echo "==> Zipping for notarization"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "==> Submitting to notarization (profile: $NOTARY_PROFILE)"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "==> Stapling ticket"
xcrun stapler staple "$APP_PATH"

echo "==> Re-zipping stapled app"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "==> Done:"
echo "$ZIP_PATH"

