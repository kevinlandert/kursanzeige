import Testing
import Foundation
@testable import KursanzeigeKit

struct FilePriceHistoryStoreTests {

    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func createHistory(close: Double) -> PriceHistory {
        PriceHistory(
            closes: [ClosePoint(date: Date(timeIntervalSince1970: 1_700_000_000), close: close)],
            fetchedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
    }

    @Test func loadReturnsNilWhenNothingIsStoredForTheSymbol() throws {
        let store = FilePriceHistoryStore(directory: try makeTempDirectory())

        #expect(store.load(for: "NESN.SW") == nil)
    }

    @Test func saveThenLoadReturnsTheSameHistory() throws {
        let store = FilePriceHistoryStore(directory: try makeTempDirectory())
        let history = createHistory(close: 77.96)

        store.save(history, for: "NESN.SW")

        #expect(store.load(for: "NESN.SW") == history)
    }

    @Test func eachSymbolKeepsItsOwnHistory() throws {
        let store = FilePriceHistoryStore(directory: try makeTempDirectory())

        store.save(createHistory(close: 1), for: "NESN.SW")
        store.save(createHistory(close: 2), for: "NOVN.SW")

        #expect(store.load(for: "NESN.SW")?.closes.first?.close == 1)
        #expect(store.load(for: "NOVN.SW")?.closes.first?.close == 2)
    }

    @Test func symbolsWithSpecialCharactersAreStored() throws {
        let store = FilePriceHistoryStore(directory: try makeTempDirectory())
        let history = createHistory(close: 12_000)

        store.save(history, for: "^SSMI")
        store.save(history, for: "EURCHF=X")

        #expect(store.load(for: "^SSMI") == history)
        #expect(store.load(for: "EURCHF=X") == history)
    }

    @Test func secondSaveReplacesTheFirst() throws {
        let store = FilePriceHistoryStore(directory: try makeTempDirectory())
        store.save(createHistory(close: 1), for: "NESN.SW")

        store.save(createHistory(close: 2), for: "NESN.SW")

        #expect(store.load(for: "NESN.SW")?.closes.first?.close == 2)
    }

    @Test func loadReturnsNilForACorruptFileInsteadOfCrashing() throws {
        let directory = try makeTempDirectory()
        let store = FilePriceHistoryStore(directory: directory)
        store.save(createHistory(close: 1), for: "NESN.SW")
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        try Data("not valid json".utf8).write(to: try #require(files.first))

        #expect(store.load(for: "NESN.SW") == nil)
    }
}
