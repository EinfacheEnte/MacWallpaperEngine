import Foundation

struct VideoEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var filename: String

    init(name: String, filename: String) {
        self.id = UUID()
        self.name = name
        self.filename = filename
    }
}

@MainActor
final class VideoLibrary: ObservableObject {
    @Published private(set) var videos: [VideoEntry] = []

    private let videosDir: URL
    private let indexURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("WallpaperEngineMac", isDirectory: true)
        videosDir = appDir.appendingPathComponent("Videos", isDirectory: true)
        indexURL = appDir.appendingPathComponent("library.json")

        try? FileManager.default.createDirectory(at: videosDir, withIntermediateDirectories: true)
        load()
    }

    /// The full file path for a library entry.
    func path(for entry: VideoEntry) -> String {
        videosDir.appendingPathComponent(entry.filename).path
    }

    /// Import one or more video files into the library folder.
    /// Files are copied so the originals can be deleted without affecting playback.
    func importVideos(from urls: [URL]) {
        let fm = FileManager.default
        for url in urls {
            let originalName = url.lastPathComponent
            var destName = originalName
            var dest = videosDir.appendingPathComponent(destName)

            // Avoid overwriting: append a number if needed
            var counter = 1
            let stem = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            while fm.fileExists(atPath: dest.path) {
                destName = "\(stem) (\(counter)).\(ext)"
                dest = videosDir.appendingPathComponent(destName)
                counter += 1
            }

            do {
                try fm.copyItem(at: url, to: dest)
                let displayName = dest.deletingPathExtension().lastPathComponent
                let entry = VideoEntry(name: displayName, filename: destName)
                videos.append(entry)
            } catch {
                NSLog("Failed to import video %@: %@", url.path, error.localizedDescription)
            }
        }
        save()
    }

    func remove(id: UUID) {
        guard let entry = videos.first(where: { $0.id == id }) else { return }
        let file = videosDir.appendingPathComponent(entry.filename)
        try? FileManager.default.removeItem(at: file)
        videos.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([VideoEntry].self, from: data) else { return }
        // Only keep entries whose files still exist
        let fm = FileManager.default
        videos = decoded.filter { fm.fileExists(atPath: videosDir.appendingPathComponent($0.filename).path) }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(videos) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}
