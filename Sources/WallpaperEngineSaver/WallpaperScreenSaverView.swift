import ScreenSaver
import AVFoundation
import AppKit

private struct VideoEntry: Codable {
    let id: String
    let name: String
    let filename: String
}

@objc(WallpaperScreenSaverView)
final class WallpaperScreenSaverView: ScreenSaverView {

    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?

    // MARK: - Init

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        let playerLayer = AVPlayerLayer()
        playerLayer.frame = bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = NSColor.black.cgColor
        self.layer?.addSublayer(playerLayer)
        self.playerLayer = playerLayer

        if let url = resolveVideoURL() {
            loadVideo(url: url)
        }
    }

    private func loadVideo(url: URL) {
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        queue.isMuted = true
        queue.automaticallyWaitsToMinimizeStalling = false
        let looper = AVPlayerLooper(player: queue, templateItem: item)
        self.player = queue
        self.looper = looper
        self.playerLayer?.player = queue
        queue.play()
    }

    // MARK: - Video resolution

    private func resolveVideoURL() -> URL? {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }

        let appDir   = appSupport.appendingPathComponent("WallpaperEngineMac")
        let videosDir = appDir.appendingPathComponent("Videos")

        // 1. Check explicit selection written by the main app
        let selectionFile = appDir.appendingPathComponent("screensaver_video.txt")
        if let selected = try? String(contentsOf: selectionFile, encoding: .utf8),
           !selected.isEmpty {
            let url = URL(fileURLWithPath: selected)
            if fm.fileExists(atPath: url.path) { return url }
        }

        // 2. Fall back to a random video from the library
        let indexFile = appDir.appendingPathComponent("library.json")
        guard let data = try? Data(contentsOf: indexFile),
              let entries = try? JSONDecoder().decode([VideoEntry].self, from: data),
              !entries.isEmpty else { return nil }

        let available = entries.filter {
            fm.fileExists(atPath: videosDir.appendingPathComponent($0.filename).path)
        }
        guard let entry = available.randomElement() else { return nil }
        return videosDir.appendingPathComponent(entry.filename)
    }

    // MARK: - ScreenSaverView

    override func startAnimation() {
        super.startAnimation()
        player?.play()
    }

    override func stopAnimation() {
        super.stopAnimation()
        player?.pause()
    }

    override func animateOneFrame() {}

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        playerLayer?.frame = bounds
    }

    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }
}
