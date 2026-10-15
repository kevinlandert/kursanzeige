import Testing
import Foundation
@testable import KursanzeigeKit

struct FileConstituentsStoreTests {

    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func sampleInstruments() -> [Instrument] {
        [
            Instrument(symbol: "NESN.SW", name: "Nestlé", group: .switzerland),
            Instrument(symbol: "ADEN.SW", name: "Adecco", group: .switzerland),
        ]
    }

    @Test func loadReturnsNilWhenNoFileExists() throws {
        let store = FileConstituentsStore(directory: try makeTempDirectory())
        #expect(store.load() == nil)
    }

    @Test func saveThenLoadRoundTrips() throws {
        let store = FileConstituentsStore(directory: try makeTempDirectory())
        let instruments = sampleInstruments()

        store.save(instruments)

        #expect(store.load() == instruments)
    }

    @Test func secondSaveOverwritesFirst() throws {
        let store = FileConstituentsStore(directory: try makeTempDirectory())
        store.save(sampleInstruments())

        let updated: [Instrument] = []
        store.save(updated)

        #expect(store.load() == updated)
    }

    @Test func savingAnEmptyListIsDistinctFromNeverHavingSaved() throws {
        // load() must distinguish "nothing persisted yet" (nil, triggers
        // reseeding from bundled defaults) from "the user emptied every
        // group" (an actual saved empty array).
        let store = FileConstituentsStore(directory: try makeTempDirectory())
        store.save([])

        #expect(store.load() == [])
    }

    @Test func loadReturnsNilForCorruptFileInsteadOfCrashing() throws {
        let directory = try makeTempDirectory()
        let store = FileConstituentsStore(directory: directory)
        try Data("not valid json".utf8).write(to: directory.appendingPathComponent("device_constituents.json"))

        #expect(store.load() == nil)
    }
}
