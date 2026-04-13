import Foundation
import AVFoundation

@MainActor
final class WallpaperPlaybackController {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var currentURL: URL?
    private var rateObservation: NSKeyValueObservation?
    private var videoOutput: AVPlayerItemVideoOutput?
    private var isPausedByUser: Bool = false

    var avPlayer: AVQueuePlayer? { player }

    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }

    func pause() {
        isPausedByUser = true
        player?.pause()
    }

    func resume() {
        isPausedByUser = false
        player?.play()
    }

    func play(url: URL) {
        if currentURL == url, player != nil {
            isPausedByUser = false
            player?.play()
            return
        }

        stop()

        currentURL = url
        isPausedByUser = false
        let item = AVPlayerItem(url: url)

        // Keep the video decode pipeline active even when the window is occluded.
        // Without this, macOS suspends frame decoding for hidden layers and it takes
        // ~1 second to restart when the desktop becomes visible again.
        let output = AVPlayerItemVideoOutput()
        item.add(output)
        self.videoOutput = output

        let queue = AVQueuePlayer()
        queue.actionAtItemEnd = .none
        queue.isMuted = true
        queue.automaticallyWaitsToMinimizeStalling = false
        let looper = AVPlayerLooper(player: queue, templateItem: item)

        self.player = queue
        self.looper = looper

        // Watch for system-initiated pauses and immediately resume
        rateObservation = queue.observe(\.rate, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.isPausedByUser else { return }
                if player.rate == 0 {
                    player.play()
                }
            }
        }

        queue.play()
    }

    func stop() {
        isPausedByUser = true
        rateObservation?.invalidate()
        rateObservation = nil
        videoOutput = nil
        player?.pause()
        looper = nil
        player = nil
        currentURL = nil
    }
}
