# WallpaperEngineMac (macOS Live Video Wallpaper)

This is a native macOS app that plays looping video wallpaper(s) on the desktop (Wallpaper Engine–like).

## Build & run

- **Xcode**: Open `Package.swift` in Xcode and run the `WallpaperEngineMac` scheme.
- **CLI**:

```bash
swift run
```

## Packaging (signed + notarized)

Build an `.app` bundle:

```bash
scripts/build_release_app.sh
```

Then sign + notarize + produce a distributable zip:

```bash
export DEVELOPER_ID_APP="Developer ID Application: Your Name (TEAMID)"
export NOTARY_PROFILE="notarytool-profile"
scripts/sign_notarize_zip.sh
```

Create the notarytool profile once:

```bash
xcrun notarytool store-credentials "notarytool-profile" --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-password"
```

## Notes

- The **Launch at login** toggle uses `ServiceManagement` (`SMAppService`). That feature generally works best when running as a properly codesigned `.app` bundle from Xcode.

