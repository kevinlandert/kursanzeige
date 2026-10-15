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
    /// A yellow that is different from `positive` and `negative`, so the
    /// line never looks like a rise or a fall. The label of the current
    /// price has this color too, so it must be clear as text.
    public let chartLine: RGBColor
    /// The box around the chart. In dark mode it is grey: a white box on
    /// black is too bright next to the yellow line.
    public let chartBorder: RGBColor
    /// The background of a selected button.
    public let accent: RGBColor
    /// The title of the sort column.
    public let accentText: RGBColor
    /// The green background of "Aktualisieren" and "Hinzufügen".
    public let action: RGBColor
    /// The text on `accent` and on `action`.
    public let buttonText: RGBColor

    /// The row bands and the plus and minus colors have measured contrast
    /// values. Light green #3A9A3A had only 3.6 to 1 on white. The chart
    /// line is dark gold: pure yellow has only 1.4 to 1 on white.
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
        chartLine: RGBColor(hex: 0x8A6500),
        chartBorder: RGBColor(hex: 0x000000),
        accent: RGBColor(hex: 0x0062D6),
        accentText: RGBColor(hex: 0x0062D6),
        action: RGBColor(hex: 0x006400),
        buttonText: RGBColor(hex: 0xFFFFFF)
    )

    /// A black page with white text gives the highest contrast. Plus,
    /// minus and the yellow chart line are light, so they are clear on black.
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
        chartLine: RGBColor(hex: 0xFFD60A),
        chartBorder: RGBColor(hex: 0x9A9AA2),
        accent: RGBColor(hex: 0x0A5FD0),
        accentText: RGBColor(hex: 0x8AB4FF),
        action: RGBColor(hex: 0x1E7B1E),
        buttonText: RGBColor(hex: 0xFFFFFF)
    )
}
