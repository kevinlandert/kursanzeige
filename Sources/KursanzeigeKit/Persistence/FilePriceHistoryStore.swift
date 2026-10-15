import Foundation

/// JSON-file-backed `PriceHistoryStoring`, with one file per symbol. Thus
/// a chart reads only its own ~50 KB file, not five years of closes for
/// every instrument. Stored in Caches: a refresh can rebuild it. A corrupt
/// or missing file gives `nil`, same policy as `FileSnapshotCache`.
struct FilePriceHistoryStore: PriceHistoryStoring {
    private let directory: URL

    init(directory: URL = FilePriceHistoryStore.defaultDirectory()) {
        self.directory = directory
    }

    func load(for symbol: String) -> PriceHistory? {
        guard let data = try? Data(contentsOf: fileURL(for: symbol)) else { return nil }
        return try? JSONDecoder().decode(PriceHistory.self, from: data)
    }

    func save(_ history: PriceHistory, for symbol: String) {
        guard let data = try? JSONEncoder().encode(history) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: fileURL(for: symbol), options: .atomic)
    }

    /// Encodes every character except letters and digits, so no symbol
    /// can add a path segment or clash with a reserved file name.
    private func fileURL(for symbol: String) -> URL {
        let filename = symbol.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? symbol
        return directory.appendingPathComponent("\(filename).json")
    }

    private static func defaultDirectory() -> URL {
        let caches = (try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        return caches.appendingPathComponent("PriceHistories", isDirectory: true)
    }
}
