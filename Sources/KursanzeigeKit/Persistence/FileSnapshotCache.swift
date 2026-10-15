import Foundation

/// JSON-file-backed `SnapshotCaching`. A corrupt or missing file is treated
/// as "no cache" rather than an error -- launching the app should never
/// crash or block on a bad cache write from a previous session.
struct FileSnapshotCache: SnapshotCaching {
    private let fileURL: URL

    init(directory: URL = FileSnapshotCache.defaultDirectory(), filename: String = "snapshot.json") {
        self.fileURL = directory.appendingPathComponent(filename)
    }

    func load() -> CachedSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(CachedSnapshot.self, from: data)
    }

    func save(_ snapshot: CachedSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func defaultDirectory() -> URL {
        (try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
    }
}
