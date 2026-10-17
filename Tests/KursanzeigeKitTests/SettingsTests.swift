import Foundation
import Testing
@testable import KursanzeigeKit

@Suite("SpeechRate")
struct SpeechRateTests {
    @Test("the tempos are 0.91, 1 and 1.1 times the default rate")
    func temposHaveTheirFactors() {
        #expect(SpeechRate.slow.factor == 0.91)
        #expect(SpeechRate.normal.factor == 1.0)
        #expect(SpeechRate.fast.factor == 1.1)
    }

    @Test("the settings show German names")
    func temposHaveGermanNames() {
        #expect(SpeechRate.allCases.map(\.displayName) == ["Langsam", "Normal", "Schnell"])
    }

    @Test("Langsamer and Schneller step to the neighbor tempo and stop at the ends")
    func stepsStopAtTheEnds() {
        #expect(SpeechRate.normal.slowerRate == .slow)
        #expect(SpeechRate.normal.fasterRate == .fast)
        #expect(SpeechRate.slow.slowerRate == nil)
        #expect(SpeechRate.fast.fasterRate == nil)
    }

    /// An app update must read the tempo that an older version stored.
    @Test("the stored texts of the tempos stay the same")
    func storedTextsStayTheSame() {
        #expect(SpeechRate.allCases.map(\.rawValue) == ["slow", "normal", "fast"])
    }

    @Test("a new install reads at Normal")
    func newInstallReadsAtNormal() {
        #expect(SpeechRate.standard == .normal)
    }
}

@Suite("Appearance")
struct AppearanceTests {
    @Test("the three choices are Hell, Dunkel and Wie iPad")
    func choicesHaveGermanNames() {
        #expect(Appearance.allCases.map(\.displayName) == ["Hell", "Dunkel", "Wie iPad"])
    }

    @Test("the line under the choices tells what the app does")
    func hintTellsWhatAppDoes() {
        #expect(Appearance.light.hint(isDeviceDark: true) == "Die App bleibt hell.")
        #expect(Appearance.dark.hint(isDeviceDark: false) == "Die App bleibt dunkel.")
        #expect(Appearance.device.hint(isDeviceDark: true) == "Die App folgt dem iPad. Jetzt: dunkel.")
        #expect(Appearance.device.hint(isDeviceDark: false) == "Die App folgt dem iPad. Jetzt: hell.")
    }

    /// An app update must read the choice that an older version stored.
    @Test("the stored texts of the appearances stay the same")
    func storedTextsStayTheSame() {
        #expect(Appearance.allCases.map(\.rawValue) == ["light", "dark", "device"])
    }

    @Test("a new install is light")
    func newInstallIsLight() {
        #expect(Appearance.standard == .light)
    }
}

@Suite("SpokenColumns")
struct SpokenColumnsTests {
    @Test("a new install reads the price and the day, as before")
    func standardReadsPriceAndDay() {
        #expect(SpokenColumns.standard == [.price, .day])
    }

    /// An app update must read the columns that an older version stored.
    @Test("the stored bits of the columns stay the same")
    func storedBitsStayTheSame() {
        #expect([SpokenColumns.price, .day, .shortRange, .longRange].map(\.rawValue) == [1, 2, 4, 8])
    }
}
