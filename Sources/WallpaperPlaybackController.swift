import Foundation
import AVFoundation

@MainActor
final class WallpaperPlaybackController {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var currentURL: URL?

    var avPlayer: AVQueuePlayer? { player }

    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func play(url: URL) {
        if currentURL == url, player != nil {
            player?.play()
            return
        }

        currentURL = url
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        queue.actionAtItemEnd = .none
        queue.isMuted = true
        let looper = AVPlayerLooper(player: queue, templateItem: item)

        self.player = queue
        self.looper = looper

        queue.play()
    }

    func stop() {
        player?.pause()
        looper = nil
        player = nil
        currentURL = nil
    }
}

