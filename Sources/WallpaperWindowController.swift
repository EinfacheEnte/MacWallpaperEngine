import Foundation
import AppKit
import CoreGraphics

@MainActor
final class WallpaperWindowController {
    private struct WindowSlot {
        let window: NSWindow
        let playerView: PlayerHostingView
        let playback: WallpaperPlaybackController
        let occlusionObserver: Any
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

        for (id, slot) in slotsByDisplayID where !keep.contains(id) {
            slot.playback.stop()
            NotificationCenter.default.removeObserver(slot.occlusionObserver)
            slot.window.orderOut(nil)
            slotsByDisplayID[id] = nil
        }
    }

    func stop() {
        for (_, slot) in slotsByDisplayID {
            slot.playback.stop()
            NotificationCenter.default.removeObserver(slot.occlusionObserver)
            slot.window.orderOut(nil)
        }
        slotsByDisplayID.removeAll()
    }

    func bringAllToFront() {
        for (_, slot) in slotsByDisplayID {
            slot.window.orderFrontRegardless()
        }
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
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none

        // Prevent macOS from hiding/unloading the window when app is in background
        window.hidesOnDeactivate = false
        window.canHide = false

        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // Just above macOS desktop wallpaper, below normal windows.
        let desktopLevel = CGWindowLevelForKey(.desktopWindow)
        window.level = NSWindow.Level(rawValue: Int(desktopLevel) + 1)

        window.title = "Wallpaper \(title)"

        let root = WallpaperRootView()
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

        // When the window becomes visible again after being occluded (e.g. switching
        // back from a fullscreen app), force it to the front immediately.
        let observer = NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: window,
            queue: .main
        ) { notification in
            guard let w = notification.object as? NSWindow else { return }
            if w.occlusionState.contains(.visible) {
                w.orderFrontRegardless()
            }
        }

        return WindowSlot(window: window, playerView: playerView, playback: playback, occlusionObserver: observer)
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
