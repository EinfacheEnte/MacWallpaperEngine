# WallpaperEngineMac

A native macOS app that plays looping video wallpapers on your desktop — like Wallpaper Engine, but for Mac.

## Install

1. Download the latest `.dmg` from [Releases](https://github.com/EinfacheEnte/MacWallpaperEngine/releases)
2. Open the DMG and drag the app to your Applications folder
3. Launch from Applications or Spotlight

> The source code is fully open — if you'd rather build from source, clone the repo and run `swift build`.

## Features

- **Live video wallpaper** — play any video file as your desktop background on a seamless loop
- **Video library** — import videos into a local library stored in `~/Library/Application Support/WallpaperEngineMac/Videos/`. Videos persist even if you delete and reinstall the app
- **Multi-monitor support** — set the same wallpaper on all displays, or choose a different video per display
- **Scale modes** — fill (crop to fit) or fit (letterbox)
- **Menu bar controls** — start, stop, apply settings, and open the settings window from the menu bar
- **Launch at login** — optional auto-start on boot
- **Sleep/wake aware** — pauses playback when your Mac sleeps, resumes on wake
- **Hot-plug detection** — automatically handles displays being connected or disconnected

## Roadmap

- [ ] **Screensaver mode** ← top priority
- [ ] Login screen wallpaper
- [ ] Video thumbnails in the library
- [ ] Drag & drop to add videos
- [ ] Playlist / wallpaper rotation on a timer
- [ ] Per-display scale mode
- [ ] Global keyboard shortcut to toggle wallpaper
- [ ] Pause on battery to save power
- [ ] Auto-start wallpaper on app launch

## Requirements

- macOS 13 (Ventura) or later

## License

Open source. Feel free to use, modify, and contribute.
