# WallpaperEngineMac (macOS Live Video Wallpaper)

This is a native macOS app that plays looping video wallpaper(s) on the desktop (Wallpaper Engine–like).

## Build & run

- **Xcode**: Open `Package.swift` in Xcode and run the `WallpaperEngineMac` scheme.
- **CLI**:

```bash
swift run
```

## Notes

- The **Launch at login** toggle uses `ServiceManagement` (`SMAppService`). That feature generally works best when running as a properly codesigned `.app` bundle from Xcode.

