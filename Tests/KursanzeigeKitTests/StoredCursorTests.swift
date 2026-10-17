import Foundation
import Testing
@testable import KursanzeigeKit

@Suite("UserDefaultsCursorStore")
@MainActor
struct StoredCursorTests {
    private func createDefaults() -> UserDefaults {
        let suiteName = "StoredCursorTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    @Test("a saved cursor stays for the next start of the app")
    func savedCursorStays() {
        let defaults = createDefaults()
        UserDefaultsCursorStore(defaults: defaults).saveCursorRowId("NESN.SW", list: "Schweiz")

        #expect(UserDefaultsCursorStore(defaults: defaults).loadCursorRowId(list: "Schweiz") == "NESN.SW")
    }

    @Test("each list keeps its own cursor")
    func eachListKeepsItsCursor() {
        let store = UserDefaultsCursorStore(defaults: createDefaults())
        store.saveCursorRowId("NESN.SW", list: "Schweiz")
        store.saveCursorRowId("AAPL", list: "USA")

        #expect(store.loadCursorRowId(list: "Schweiz") == "NESN.SW")
        #expect(store.loadCursorRowId(list: "USA") == "AAPL")
        #expect(store.loadCursorRowId(list: "Welt") == nil)
    }
}
