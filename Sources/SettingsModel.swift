import Foundation
import AppKit

@MainActor
final class SettingsModel: ObservableObject {
    enum Mode: String, CaseIterable, Codable {
        case sameForAll
        case perDisplay
    }

    enum ScaleMode: String, CaseIterable, Codable {
        case fill
        case fit
    }

    struct DisplayInfo: Identifiable, Hashable {
        let id: String
        let name: String
    }

    @Published var mode: Mode {
        didSet { persist() }
    }

    @Published var scaleMode: ScaleMode {
        didSet { persist() }
    }

    @Published var sameVideoPath: String {
        didSet { persist() }
    }

    @Published var launchAtLogin: Bool {
        didSet { persist() }
    }

    @Published private(set) var knownDisplays: [DisplayInfo] = []

    @Published private var perDisplayVideoPath: [String: String] {
        didSet { persist() }
    }

    private let store = UserDefaults.standard

    private enum Keys {
        static let mode = "settings.mode"
        static let scaleMode = "settings.scaleMode"
        static let sameVideoPath = "settings.sameVideoPath"
        static let perDisplayVideoPath = "settings.perDisplayVideoPath"
        static let launchAtLogin = "settings.launchAtLogin"
    }

    init() {
        mode = Mode(rawValue: store.string(forKey: Keys.mode) ?? "") ?? .sameForAll
        scaleMode = ScaleMode(rawValue: store.string(forKey: Keys.scaleMode) ?? "") ?? .fill
        sameVideoPath = store.string(forKey: Keys.sameVideoPath) ?? ""
        perDisplayVideoPath = store.dictionary(forKey: Keys.perDisplayVideoPath) as? [String: String] ?? [:]
        launchAtLogin = store.bool(forKey: Keys.launchAtLogin)
    }

    func refreshDisplays() {
        knownDisplays = DisplayManager().currentDisplays().map { d in
            DisplayInfo(id: d.id, name: d.name)
        }
    }

    func videoPath(forDisplayID id: String) -> String {
        perDisplayVideoPath[id] ?? ""
    }

    func chooseSameVideo() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.movie]
        if panel.runModal() == .OK, let url = panel.url {
            sameVideoPath = url.path
        }
    }

    func chooseVideo(forDisplayID id: String) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.movie]
        if panel.runModal() == .OK, let url = panel.url {
            perDisplayVideoPath[id] = url.path
        }
    }

    func resolvedVideoPath(forDisplayID id: String) -> String? {
        switch mode {
        case .sameForAll:
            return sameVideoPath.isEmpty ? nil : sameVideoPath
        case .perDisplay:
            let p = perDisplayVideoPath[id] ?? ""
            return p.isEmpty ? nil : p
        }
    }

    private func persist() {
        store.set(mode.rawValue, forKey: Keys.mode)
        store.set(scaleMode.rawValue, forKey: Keys.scaleMode)
        store.set(sameVideoPath, forKey: Keys.sameVideoPath)
        store.set(perDisplayVideoPath, forKey: Keys.perDisplayVideoPath)
        store.set(launchAtLogin, forKey: Keys.launchAtLogin)
    }
}

