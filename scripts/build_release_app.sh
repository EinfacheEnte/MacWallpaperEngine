#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="${APP_NAME:-WallpaperEngineMac}"
BUNDLE_ID="${BUNDLE_ID:-com.einfacheente.macwallpaperengine}"
OUT_DIR="$ROOT_DIR/build/out"
APP_PATH="$OUT_DIR/$APP_NAME.app"

SAVER_NAME="WallpaperEngineMac"
SAVER_EXEC="WallpaperEngineSaver"
SAVER_BUNDLE_ID="${BUNDLE_ID}.screensaver"
SAVER_PATH="$APP_PATH/Contents/Library/Screen Savers/$SAVER_NAME.saver"

echo "==> Building main app (release)"
swift build -c release

EXEC_PATH="$(swift build -c release --show-bin-path)/$APP_NAME"
if [[ ! -f "$EXEC_PATH" ]]; then
  echo "ERROR: Binary not found at: $EXEC_PATH" >&2
  exit 1
fi

echo "==> Creating .app bundle"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

cp "$EXEC_PATH" "$APP_PATH/Contents/MacOS/$APP_NAME"

# App icon
ICON_PATH="$ROOT_DIR/assets/AppIcon.icns"
if [[ -f "$ICON_PATH" ]]; then
  cp "$ICON_PATH" "$APP_PATH/Contents/Resources/AppIcon.icns"
fi

cat > "$APP_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>Wallpaper Engine</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <false/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
</dict>
</plist>
PLIST

# ── Screen Saver ──────────────────────────────────────────────────────────────

echo "==> Building screen saver"
mkdir -p "$SAVER_PATH/Contents/MacOS"
mkdir -p "$SAVER_PATH/Contents/Resources"

swiftc \
  -target arm64-apple-macos14.0 \
  -emit-library \
  -Xlinker -bundle \
  -module-name WallpaperEngineSaver \
  -framework ScreenSaver \
  -framework AVFoundation \
  -framework AppKit \
  -framework Foundation \
  "$ROOT_DIR/Sources/WallpaperEngineSaver/WallpaperScreenSaverView.swift" \
  -o "$SAVER_PATH/Contents/MacOS/$SAVER_EXEC"

# Copy icon into saver too
if [[ -f "$ICON_PATH" ]]; then
  cp "$ICON_PATH" "$SAVER_PATH/Contents/Resources/AppIcon.icns"
fi

cat > "$SAVER_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>${SAVER_EXEC}</string>
  <key>CFBundleIdentifier</key>
  <string>${SAVER_BUNDLE_ID}</string>
  <key>CFBundleName</key>
  <string>${SAVER_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>Wallpaper Engine</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundlePackageType</key>
  <string>BNDL</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>NSPrincipalClass</key>
  <string>WallpaperScreenSaverView</string>
</dict>
</plist>
PLIST

# ── Ad-hoc signing ────────────────────────────────────────────────────────────
# Signs the app and embedded saver with a local identity so macOS doesn't
# report it as "damaged" on other machines. This is free and requires no
# Apple Developer account. Users may still see "unidentified developer" but
# can bypass it via right-click → Open.

echo "==> Ad-hoc signing"
# Strip .DS_Store and resource forks that break codesign
find "$APP_PATH" -name ".DS_Store" -delete
xattr -cr "$APP_PATH"
codesign --force --deep --sign - "$APP_PATH"

echo "==> Output:"
echo "  App:         $APP_PATH"
echo "  ScreenSaver: $SAVER_PATH"
