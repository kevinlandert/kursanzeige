import Testing
import Foundation
@testable import KursanzeigeKit

struct FileSnapshotCacheTests {

    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func sampleSnapshot() -> CachedSnapshot {
        let instrument = Instrument(symbol: "NESN.SW", name: "Nestlé", group: .switzerland)
        let row = InstrumentRow(instrument: instrument, price: 77.96, asOf: Date(timeIntervalSince1970: 1_700_000_000), dayChangePercent: 0.3, threeMonthChangePercent: -4.1, oneYearChangePercent: -12.8)
        return CachedSnapshot(rows: [row], savedAt: Date(timeIntervalSince1970: 1_700_000_100))
    }

    @Test func loadReturnsNilWhenNoFileExists() throws {
        let cache = FileSnapshotCache(directory: try makeTempDirectory())
        #expect(cache.load() == nil)
    }

    @Test func saveThenLoadRoundTrips() throws {
        let cache = FileSnapshotCache(directory: try makeTempDirectory())
        let snapshot = sampleSnapshot()

        cache.save(snapshot)
        let loaded = cache.load()

        #expect(loaded == snapshot)
    }

    /// A file from an older version of the app has rows without a unit.
    /// The table must still show its prices after an update.
    @Test("a stored row without a unit loads, with no unit")
    func rowWithoutUnitLoads() throws {
        let directory = try makeTempDirectory()
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(sampleSnapshot())) as! [String: Any]
        var rows = json["rows"] as! [[String: Any]]
        rows[0]["unit"] = nil
        json["rows"] = rows
        try JSONSerialization.data(withJSONObject: json).write(to: directory.appendingPathComponent("snapshot.json"))

        let loaded = FileSnapshotCache(directory: directory).load()

        #expect(loaded?.rows.first?.price == 77.96)
        #expect(loaded?.rows.first?.unit == nil)
    }

    @Test func secondSaveOverwritesFirst() throws {
        let cache = FileSnapshotCache(directory: try makeTempDirectory())
        cache.save(sampleSnapshot())

        let updated = CachedSnapshot(rows: [], savedAt: Date(timeIntervalSince1970: 1_800_000_000))
        cache.save(updated)

        #expect(cache.load() == updated)
    }

    @Test func loadReturnsNilForCorruptFileInsteadOfCrashing() throws {
        let directory = try makeTempDirectory()
        let cache = FileSnapshotCache(directory: directory)
        try Data("not valid json".utf8).write(to: directory.appendingPathComponent("snapshot.json"))

        #expect(cache.load() == nil)
    }
}
