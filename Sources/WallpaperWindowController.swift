import Foundation
import AppKit
import CoreGraphics

@MainActor
final class WallpaperWindowController {
    private struct WindowSlot {
        let window: NSWindow
        let playerView: PlayerHostingView
        let playback: WallpaperPlaybackController
    }

    private var slotsByDisplayID: [String: WindowSlot] = [:]

    func pauseAll() {
        for (_, slot) in slotsByDisplayID {
            slot.playback.pause()
        }
    }

    func resumeAll() {
        for (_, slot) in slotsByDisplayID {
            slot.playback.resume()
        }
    }

    func apply(settings: SettingsModel, displays: [DisplayDescriptor]) {
        // Create/update windows for current displays
        var keep: Set<String> = []
        for display in displays {
            keep.insert(display.id)

            if let existing = slotsByDisplayID[display.id] {
                existing.window.setFrame(display.frame, display: true)
                existing.window.orderFrontRegardless()
                existing.playerView.scaleMode = settings.scaleMode
                applyPlayback(to: existing, settings: settings, displayID: display.id)
            } else {
                let slot = makeWallpaperWindow(frame: display.frame, title: display.name)
                slot.window.orderFrontRegardless()
                slot.playerView.scaleMode = settings.scaleMode
                applyPlayback(to: slot, settings: settings, displayID: display.id)
                slotsByDisplayID[display.id] = slot
            }
        }

        // Tear down windows for removed displays
        for (id, slot) in slotsByDisplayID where !keep.contains(id) {
            slot.playback.stop()
            slot.window.orderOut(nil)
            slotsByDisplayID[id] = nil
        }
    }

    func stop() {
        for (_, slot) in slotsByDisplayID {
            slot.playback.stop()
            slot.window.orderOut(nil)
        }
        slotsByDisplayID.removeAll()
    }

    private func applyPlayback(to slot: WindowSlot, settings: SettingsModel, displayID: String) {
        guard let path = settings.resolvedVideoPath(forDisplayID: displayID) else {
            slot.playerView.player = nil
            slot.playback.stop()
            return
        }
        let url = URL(fileURLWithPath: path)
        slot.playback.play(url: url)
        slot.playback.setMuted(true)
        slot.playerView.player = slot.playback.avPlayer
    }

    private func makeWallpaperWindow(frame: CGRect, title: String) -> WindowSlot {
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = true
        window.hasShadow = false
        window.backgroundColor = .black
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isReleasedWhenClosed = false

        // Desktop-level window (behind normal apps).
        let desktopLevel = CGWindowLevelForKey(.desktopWindow)
        window.level = NSWindow.Level(rawValue: Int(desktopLevel))

        window.title = "Wallpaper \(title)"

        let root = WallpaperRootView()
        root.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = root

        let playerView = PlayerHostingView()
        playerView.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: root.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])

        let playback = WallpaperPlaybackController()
        return WindowSlot(window: window, playerView: playerView, playback: playback)
    }
}

private final class WallpaperRootView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }

    required init?(coder: NSCoder) {
        nil
    }
}

