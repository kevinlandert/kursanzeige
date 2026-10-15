import Testing
import Foundation
@testable import KursanzeigeKit

struct ConstituentsTests {

    @Test func loadsAllFiveGroups() throws {
        let instruments = try Constituents.load()
        let groupsPresent = Set(instruments.map(\.group))
        #expect(groupsPresent == Set(MarketGroup.allCases))
    }

    @Test func everyGroupHasBetweenFourAndFiftyInstruments() throws {
        // Währungen is a deliberately closed set (USD/EUR/GBP/JPY vs. CHF),
        // so its floor is 4, not the general 5.
        let instruments = try Constituents.load()
        for group in MarketGroup.allCases {
            let count = instruments.filter { $0.group == group }.count
            #expect(count >= 4, "\(group.rawValue) has only \(count) constituents")
            #expect(count <= 50, "\(group.rawValue) has \(count) constituents, over the 50 cap")
        }
    }

    @Test func symbolsAreUniqueWithinEachGroup() throws {
        // The same symbol legitimately appears in more than one group (e.g.
        // the SMI index is both "Schweiz" and part of "Index"), but must
        // not repeat within a single group -- that would render as a
        // duplicate row with a duplicate SwiftUI identity.
        let instruments = try Constituents.load()
        for group in MarketGroup.allCases {
            let symbols = instruments.filter { $0.group == group }.map(\.symbol)
            #expect(Set(symbols).count == symbols.count, "\(group.rawValue) has a duplicate symbol")
        }
    }

    @Test func noInstrumentHasAnEmptyNameOrSymbol() throws {
        let instruments = try Constituents.load()
        for instrument in instruments {
            #expect(!instrument.symbol.isEmpty)
            #expect(!instrument.name.isEmpty)
        }
    }

    @Test func currencyGroupHasFewEnoughToFitOnePageOfSix() throws {
        // Prototype requirement: the smallest group (Währungen) fits on one
        // screen without scrolling, so its count must be <= the row count
        // shown on screen at once.
        let instruments = try Constituents.load()
        let count = instruments.filter { $0.group == .currencies }.count
        #expect(count == 6)
    }

    @Test func switzerlandGroupIsLargeEnoughToRequireScrolling() throws {
        let instruments = try Constituents.load()
        let count = instruments.filter { $0.group == .switzerland }.count
        #expect(count == 12)
    }
}
