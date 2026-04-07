import AppKit
import AVFoundation

final class PlayerHostingView: NSView {
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var scaleMode: SettingsModel.ScaleMode = .fill {
        didSet { applyScale() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = AVPlayerLayer()
        playerLayer.backgroundColor = NSColor.black.cgColor
        applyScale()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func applyScale() {
        switch scaleMode {
        case .fill:
            playerLayer.videoGravity = .resizeAspectFill
        case .fit:
            playerLayer.videoGravity = .resizeAspect
        }
    }
}

