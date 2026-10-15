import Foundation

/// JSON-file-backed `ConstituentsStoring`. Stored in Application Support
/// rather than Caches -- this isn't rebuildable from a refresh, so it
/// shouldn't be treated as disposable. A corrupt file is treated the same
/// as a missing one (`nil`), same policy as `FileSnapshotCache`.
struct FileConstituentsStore: ConstituentsStoring {
    private let fileURL: URL

    init(directory: URL = FileConstituentsStore.defaultDirectory(), filename: String = "device_constituents.json") {
        self.fileURL = directory.appendingPathComponent(filename)
    }

    func load() -> [Instrument]? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode([Instrument].self, from: data)
    }

    func save(_ instruments: [Instrument]) {
        guard let data = try? JSONEncoder().encode(instruments) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func defaultDirectory() -> URL {
        (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
    }
}
