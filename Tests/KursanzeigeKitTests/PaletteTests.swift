import Testing
@testable import KursanzeigeKit

@Suite("RGBColor")
struct RGBColorTests {
    @Test("black text on white has the highest contrast, 21 to 1")
    func blackOnWhiteHasHighestContrast() {
        #expect(RGBColor(hex: 0x000000).contrastRatio(to: RGBColor(hex: 0xFFFFFF)) == 21)
    }

    @Test("a color on itself has no contrast, 1 to 1")
    func colorOnItselfHasNoContrast() {
        let grey = RGBColor(hex: 0x777777)
        #expect(grey.contrastRatio(to: grey) == 1)
    }

    @Test("the contrast is the same in both directions")
    func contrastIsSymmetric() {
        let green = RGBColor(hex: 0x006400)
        let white = RGBColor(hex: 0xFFFFFF)
        #expect(green.contrastRatio(to: white) == white.contrastRatio(to: green))
    }

    @Test("grey #777777 on white is just below the 4.5 to 1 minimum")
    func midGreyOnWhiteIsJustBelowMinimum() {
        let ratio = RGBColor(hex: 0x777777).contrastRatio(to: RGBColor(hex: 0xFFFFFF))
        #expect(ratio > 4.47 && ratio < 4.48)
    }

    @Test("the hex value gives the three channels")
    func hexValueGivesChannels() {
        let color = RGBColor(hex: 0x1F2633)
        #expect(color.red == 0x1F)
        #expect(color.green == 0x26)
        #expect(color.blue == 0x33)
    }
}

/// The person who uses the app has low vision. Each text must have a
/// contrast of at least 4.5 to 1 (WCAG AA) on each background where it
/// shows, in light and in dark.
@Suite("Palette")
struct PaletteTests {
    private static let minimumTextContrast = 4.5
    /// WCAG minimum for a button edge against the page.
    private static let minimumButtonContrast = 3.0

    @Test("text, grey text, plus and minus colors are clear on each table background", arguments: [Palette.light, Palette.dark])
    func valueColorsAreClearOnTableBackgrounds(palette: Palette) {
        let backgrounds = [palette.background, palette.headerBackground, palette.rowBackgroundEven, palette.rowBackgroundOdd]
        for text in [palette.text, palette.mutedText, palette.positive, palette.negative] {
            for background in backgrounds {
                #expect(text.contrastRatio(to: background) >= Self.minimumTextContrast)
            }
        }
    }

    @Test("the chart line and the sort column title are clear on the page and the header", arguments: [Palette.light, Palette.dark])
    func chartLineAndSortTitleAreClearOnPageAndHeader(palette: Palette) {
        for text in [palette.chartLine, palette.accentText] {
            #expect(text.contrastRatio(to: palette.background) >= Self.minimumTextContrast)
            #expect(text.contrastRatio(to: palette.headerBackground) >= Self.minimumTextContrast)
        }
    }

    @Test("button text is clear on a blue and on a green button", arguments: [Palette.light, Palette.dark])
    func buttonTextIsClearOnButtons(palette: Palette) {
        #expect(palette.buttonText.contrastRatio(to: palette.accent) >= Self.minimumTextContrast)
        #expect(palette.buttonText.contrastRatio(to: palette.action) >= Self.minimumTextContrast)
    }

    /// The grey of a button is almost the same as the page, so only its
    /// border shows where the button is.
    @Test("the border of a grey button stands out from the page and from the button", arguments: [Palette.light, Palette.dark])
    func greyButtonBorderStandsOut(palette: Palette) {
        #expect(palette.buttonBorder.contrastRatio(to: palette.background) >= Self.minimumButtonContrast)
        #expect(palette.buttonBorder.contrastRatio(to: palette.headerBackground) >= Self.minimumButtonContrast)
    }

    @Test("a blue or a green button stands out from the dark page", arguments: [Palette.dark])
    func buttonsStandOutFromDarkPage(palette: Palette) {
        #expect(palette.accent.contrastRatio(to: palette.background) >= Self.minimumButtonContrast)
        #expect(palette.action.contrastRatio(to: palette.background) >= Self.minimumButtonContrast)
    }

    @Test("the light palette keeps the plus and minus colors of the first version")
    func lightPaletteKeepsKnownColors() {
        #expect(Palette.light.positive == RGBColor(hex: 0x006400))
        #expect(Palette.light.negative == RGBColor(hex: 0xB00000))
    }

    @Test("the chart line is yellow on black and dark gold on white, because yellow on white is not clear")
    func chartLineIsYellow() {
        #expect(Palette.dark.chartLine == RGBColor(hex: 0xFFD60A))
        #expect(Palette.light.chartLine == RGBColor(hex: 0x8A6500))
    }

    @Test("the dark palette has a black page and white text")
    func darkPaletteHasBlackPageAndWhiteText() {
        #expect(Palette.dark.background == RGBColor(hex: 0x000000))
        #expect(Palette.dark.text == RGBColor(hex: 0xFFFFFF))
    }
}

@Suite("Appearance")
struct AppearanceTests {
    @Test("the other appearance of light is dark, and of dark is light")
    func toggledAppearanceIsTheOther() {
        #expect(Appearance.light.toggled == .dark)
        #expect(Appearance.dark.toggled == .light)
    }

    @Test("the stored text gives the same appearance again")
    func storedTextGivesSameAppearance() {
        for appearance in [Appearance.light, Appearance.dark] {
            #expect(Appearance(rawValue: appearance.rawValue) == appearance)
        }
    }
}
