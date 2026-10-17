/// All colors of the app, one set for light and one set for dark. Each
/// text color has a contrast of at least 4.5 to 1 on each background
/// where it shows. `PaletteTests` checks this rule.
public struct Palette: Sendable, Equatable {
    public let background: RGBColor
    /// The table header and the grey buttons.
    public let headerBackground: RGBColor
    /// The edge of a grey button that accepts a tap. The grey is almost
    /// the same as the page, so the border shows the button.
    public let buttonBorder: RGBColor
    public let rowBackgroundEven: RGBColor
    public let rowBackgroundOdd: RGBColor
    public let text: RGBColor
    /// The "Tag" value when the last close is not from today.
    public let mutedText: RGBColor
    public let positive: RGBColor
    public let negative: RGBColor
    /// The box around the chart. In dark mode it is grey: a white box on
    /// black is too bright next to the colored line.
    public let chartBorder: RGBColor
    /// The background of a selected button.
    public let accent: RGBColor
    /// The title of the sort column.
    public let accentText: RGBColor
    /// The green background of "Aktualisieren" and "Hinzufügen".
    public let action: RGBColor
    /// The text on `accent` and on `action`.
    public let buttonText: RGBColor
    /// The yellow fill of the cursor row, as in Schlagzeilen.
    public let cursor: RGBColor
    /// The text on `cursor`. It stays black in both sets, so the reader
    /// finds the cursor row the same way.
    public let cursorText: RGBColor
    /// The "Tag" value on `cursor` when the last close is not from today.
    public let cursorMutedText: RGBColor
    /// Plus and minus on `cursor`: the dark colors of the light set, also
    /// in dark, because the light colors are not clear on yellow.
    public let cursorPositive: RGBColor
    public let cursorNegative: RGBColor
    /// The thick border of the cursor row. It is the color of the text, so
    /// it stands out from the page.
    public let cursorBorder: RGBColor
    /// The fill of Vorlesen and Pause, and of the status line during Vorlesen.
    public let primary: RGBColor
    /// The text on `primary`.
    public let primaryText: RGBColor
    /// The fill of the status line when Vorlesen does not run.
    public let neutralFill: RGBColor
    /// The fill of Öffnen and Schliessen: black in light, white in dark.
    public let invertedFill: RGBColor
    /// The text on `invertedFill`.
    public let invertedText: RGBColor
    /// The border of Vorherige and Nächste.
    public let outline: RGBColor

    /// The row bands and the plus and minus colors have measured contrast
    /// values. Light green #3A9A3A had only 3.6 to 1 on white.
    public static let light = Palette(
        background: RGBColor(hex: 0xFFFFFF),
        headerBackground: RGBColor(hex: 0xF2F2F7),
        buttonBorder: RGBColor(hex: 0x7C7C84),
        rowBackgroundEven: RGBColor(hex: 0xFFFFFF),
        rowBackgroundOdd: RGBColor(hex: 0xE3E8F0),
        text: RGBColor(hex: 0x000000),
        mutedText: RGBColor(hex: 0x5E5E66),
        positive: RGBColor(hex: 0x006400),
        negative: RGBColor(hex: 0xB00000),
        chartBorder: RGBColor(hex: 0x000000),
        accent: RGBColor(hex: 0x0062D6),
        accentText: RGBColor(hex: 0x0062D6),
        action: RGBColor(hex: 0x006400),
        buttonText: RGBColor(hex: 0xFFFFFF),
        cursor: RGBColor(hex: 0xFFE14D),
        cursorText: RGBColor(hex: 0x111111),
        cursorMutedText: RGBColor(hex: 0x4A4A50),
        cursorPositive: RGBColor(hex: 0x006400),
        cursorNegative: RGBColor(hex: 0xB00000),
        cursorBorder: RGBColor(hex: 0x111111),
        primary: RGBColor(hex: 0x0A3D91),
        primaryText: RGBColor(hex: 0xFFFFFF),
        neutralFill: RGBColor(hex: 0xF2F2F7),
        invertedFill: RGBColor(hex: 0x111111),
        invertedText: RGBColor(hex: 0xFFFFFF),
        outline: RGBColor(hex: 0x111111)
    )

    /// A black page with white text gives the highest contrast. Plus and
    /// minus are light, so they are clear on black.
    public static let dark = Palette(
        background: RGBColor(hex: 0x000000),
        headerBackground: RGBColor(hex: 0x1C1C1E),
        buttonBorder: RGBColor(hex: 0x8E8E93),
        rowBackgroundEven: RGBColor(hex: 0x000000),
        rowBackgroundOdd: RGBColor(hex: 0x1F2633),
        text: RGBColor(hex: 0xFFFFFF),
        mutedText: RGBColor(hex: 0x9A9AA2),
        positive: RGBColor(hex: 0x4CD964),
        negative: RGBColor(hex: 0xFF6B6B),
        chartBorder: RGBColor(hex: 0x9A9AA2),
        accent: RGBColor(hex: 0x0A5FD0),
        accentText: RGBColor(hex: 0x8AB4FF),
        action: RGBColor(hex: 0x1E7B1E),
        buttonText: RGBColor(hex: 0xFFFFFF),
        cursor: RGBColor(hex: 0xFFD60A),
        cursorText: RGBColor(hex: 0x111111),
        cursorMutedText: RGBColor(hex: 0x4A4A50),
        cursorPositive: RGBColor(hex: 0x006400),
        cursorNegative: RGBColor(hex: 0xB00000),
        cursorBorder: RGBColor(hex: 0xFFFFFF),
        primary: RGBColor(hex: 0x0A5FD0),
        primaryText: RGBColor(hex: 0xFFFFFF),
        neutralFill: RGBColor(hex: 0x2C2C2E),
        invertedFill: RGBColor(hex: 0xFFFFFF),
        invertedText: RGBColor(hex: 0x111111),
        outline: RGBColor(hex: 0xFFFFFF)
    )
}
