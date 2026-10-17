import SwiftUI
import KursanzeigeKit

/// All sizes and colors live here so the "make everything bigger/bolder"
/// requirement (this app is for someone with low vision) stays a one-file
/// change instead of a hunt through every view.
enum Theme {
    // The color values are in `Palette`, one set for light and one for dark.
    // A value that rounds to 0.0 shows in `neutral`. Each percent also has
    // a +/− sign, so color is never the only signal.
    static let text = Color.palette(\.text)
    /// Grey text for a value that is not from today.
    static let mutedText = Color.palette(\.mutedText)
    static let positive = Color.palette(\.positive)
    static let negative = Color.palette(\.negative)
    static let neutral = text
    static let background = Color.palette(\.background)
    static let headerBackground = Color.palette(\.headerBackground)
    static let rowBackgroundEven = Color.palette(\.rowBackgroundEven)
    static let rowBackgroundOdd = Color.palette(\.rowBackgroundOdd)
    /// The background of a selected button, with `buttonText` on it.
    static let accent = Color.palette(\.accent)
    /// The title of the sort column.
    static let accentText = Color.palette(\.accentText)
    /// The green background of "Aktualisieren" and "Hinzufügen".
    static let action = Color.palette(\.action)
    static let buttonText = Color.palette(\.buttonText)
    static let buttonBorder = Color.palette(\.buttonBorder)
    static let buttonBorderWidth: CGFloat = 2
    /// The yellow cursor row, its text colors and its thick border. See
    /// `Palette.cursor`.
    static let cursor = Color.palette(\.cursor)
    static let cursorText = Color.palette(\.cursorText)
    static let cursorMutedText = Color.palette(\.cursorMutedText)
    static let cursorPositive = Color.palette(\.cursorPositive)
    static let cursorNegative = Color.palette(\.cursorNegative)
    static let cursorBorder = Color.palette(\.cursorBorder)
    static let cursorBorderWidth: CGFloat = 4
    /// The three looks of the bottom buttons. See `ControlLook`.
    static let primary = Color.palette(\.primary)
    static let primaryText = Color.palette(\.primaryText)
    static let neutralFill = Color.palette(\.neutralFill)
    static let invertedFill = Color.palette(\.invertedFill)
    static let invertedText = Color.palette(\.invertedText)
    static let outline = Color.palette(\.outline)
    // `.separator` is translucent and easy to miss. `.opaqueSeparator` is
    // the solid system line, and it also changes with dark mode.
    static let separator = Color(uiColor: .opaqueSeparator)

    /// Atkinson Hyperlegible Next, from the Braille Institute. It makes
    /// similar letters and digits clearly different for low vision, e.g.
    /// "I", "l" and "1". Its weights go from 200 to 800: `.heavy` shows as
    /// 800. The digits of `monospacedDigit()` have the same width, so the
    /// table columns stay in line.
    private static let fontFamily = "Atkinson Hyperlegible Next"

    /// A fixed size, as `Font.system(size:)`: the sizes are already large,
    /// and Dynamic Type would break the table layout. All text is bold,
    /// because thick strokes are easier to read with low vision. Only a few
    /// key numbers use `.heavy`.
    static func font(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.custom(fontFamily, fixedSize: size).weight(weight)
    }

    static let nameFontSize: CGFloat = 30
    static let nameFont = font(size: nameFontSize)
    static let valueFont = font(size: 30).monospacedDigit()
    /// Just the leading +/− sign on a value cell: bigger and heavier than the
    /// digits so direction reads before color does.
    static let signFont = font(size: 34, weight: .heavy).monospacedDigit()
    static let headerFont = font(size: 26)
    /// The thick chart line. Its color is different from `positive` and
    /// `negative`, so the line never looks like a rise or a fall.
    static let chartLineColor = Color.palette(\.chartLine)
    static let chartLineWidth: CGFloat = 12
    /// The space between the box and the first and last point of the line.
    /// A round line end goes half the line width past its point. Thus the
    /// full line width leaves a gap of half the width to the box.
    static let chartLineInset: CGFloat = chartLineWidth
    /// The high, low and current labels on the right axis: large and bold
    /// so they read at a glance, as every other number in this app.
    static let chartAxisFont = font(size: 46, weight: .heavy).monospacedDigit()
    /// The instrument name. A long name shrinks to one line, so the chart
    /// keeps its height.
    static let chartTitleFont = font(size: 128)
    /// The currency next to the title. Half the title size: the name
    /// stays the main text.
    static let chartCurrencyFont = font(size: 64)
    static let chartCurrencyGap: CGFloat = 16
    /// "Lädt …" and the error text in place of the chart.
    static let chartMessageFont = font(size: 64)
    /// The whole-range percent-change line below the chart -- deliberately
    /// the single biggest text on this screen, since it's the one-number
    /// summary of everything else on it.
    static let chartRangeChangeFont = font(size: 84, weight: .heavy).monospacedDigit()
    /// Extra gap between the chart's right-hand axis labels and the plot's
    /// own border, beyond Swift Charts' default spacing -- otherwise the
    /// high/low/current numbers sit almost flush against the box edge.
    static let chartAxisLabelMargin: CGFloat = 12
    /// The box around the plot. It is thicker than the grid lines, so the
    /// edge of the chart is clear. In dark mode it is grey, not white.
    static let chartBorderColor = Color.palette(\.chartBorder)
    static let chartBorderWidth: CGFloat = 3
    /// The two horizontal lines at the exact high/low close -- dashed so
    /// they read as "this is the line that explains that label" rather
    /// than blending into the regular automatic grid.
    static let chartExtremeLineColor = Theme.text
    static let chartExtremeLineWidth: CGFloat = 2.5
    static let chartExtremeLineDash: [CGFloat] = [8, 5]
    /// The smallest gap between the current price label and the high or
    /// low label, as a part of the high-low range. A label nearer to them
    /// moves away. The labels are large, so they need a wide gap.
    static let chartCurrentPriceLabelGapShare: Double = 0.16
    /// The largest part of the chart page height that the chart takes.
    /// More makes the title shrink, because the page has no more space.
    static let chartHeightShare: CGFloat = 0.45
    /// In landscape the title, the range buttons and the change are in a
    /// column at the left of the chart, with this part of the width.
    static let chartLandscapeInfoShare: CGFloat = 0.38
    static let chartLandscapeColumnGap: CGFloat = 24
    /// The chart never gets lower, also on a small screen.
    static let chartMinimumHeight: CGFloat = 250
    /// The bar at the bottom of the table and the chart page: a 3 pt rule
    /// over it, the status line, and four buttons, as in Schlagzeilen.
    static let bottomBarRuleWidth: CGFloat = 3
    static let bottomBarSpacing: CGFloat = 12
    static let bottomBarHorizontalPadding: CGFloat = 24
    static let bottomBarTopPadding: CGFloat = 12
    static let bottomBarBottomPadding: CGFloat = 20
    static let bottomButtonSpacing: CGFloat = 16
    static let bottomButtonHeight: CGFloat = 96
    static let bottomButtonCornerRadius: CGFloat = 20
    static let bottomButtonBorderWidth: CGFloat = 3
    static let bottomButtonFont = font(size: 28)
    static let bottomButtonSymbolFont = Font.system(size: 28, weight: .bold)
    static let bottomButtonSymbolSpacing: CGFloat = 12
    static let bottomButtonHorizontalPadding: CGFloat = 12
    static let statusLineFont = font(size: 24)
    static let statusLineCornerRadius: CGFloat = 12
    static let statusLineHorizontalPadding: CGFloat = 16
    static let statusLineVerticalPadding: CGFloat = 10
    /// The round number badge at the start of each row. The cursor row
    /// has a black badge with a yellow number.
    static let numberBadgeSize: CGFloat = 52
    static let numberBadgeFont = font(size: 24).monospacedDigit()
    static let numberBadgeBorderWidth: CGFloat = 3
    /// The badge and a gap to the name.
    static let numberColumnWidth: CGFloat = numberBadgeSize + 14
    /// Grey text on a grey button: it shows "not available" at once. The
    /// grey has a tested contrast, so the text stays clear.
    static let disabledButtonForeground = mutedText
    /// The smallest gap between the text and the border of a choice
    /// button. A longer word gets smaller and does not touch the border.
    static let choiceButtonTextInset: CGFloat = 8
    static let groupButtonFont = font(size: 24)
    static let refreshButtonFont = font(size: 26)
    static let statusFont = font(size: 20)
    static let timestampFont = font(size: 24)
    static let progressFont = font(size: 22)

    static let rowVerticalPadding: CGFloat = 14
    /// Floor for row height: two lines of `nameFont` at ~1.1x tight line
    /// spacing, plus padding on both edges, so a name that wraps to two
    /// lines (e.g. "Stoxx Basic / Resources") is never clipped. In practice
    /// this rarely binds -- `PerformanceTableView` usually computes a taller
    /// row to fill the screen -- it only matters as a hard floor on small
    /// screens or groups with many rows.
    static let minRowHeight: CGFloat = nameFontSize * 1.1 * 2 + rowVerticalPadding * 2
    /// Margin between the screen edge and everything on the page (top bar,
    /// group buttons, the table's outer border).
    static let pageMargin: CGFloat = 12
    /// Inset between the table's rounded border and the header/row text --
    /// separate from `pageMargin` so the two don't stack into a wide,
    /// wasted gutter on each side.
    static let rowInset: CGFloat = 16
    static let cornerRadius: CGFloat = 14
    /// Fixed rather than measured: the table divides remaining height by 8
    /// using this constant, so header and row-height math stay in sync.
    static let headerHeight: CGFloat = 76
    static let columnDividerWidth: CGFloat = 3
    /// Fixed height of the top bar (timestamp, progress/failure status,
    /// settings, refresh). Locking this down means the row's content can
    /// change (spinner in/out, progress text in/out) without ever resizing
    /// the bar itself, which would otherwise push the group selector and
    /// table down and back up.
    static let topBarHeight: CGFloat = 72
    /// The gap between the buttons of the top bar. A wide gap makes a tap
    /// on the wrong button less probable.
    static let topBarButtonGap: CGFloat = 40
}

/// Proportional column widths shared by the header and every row so they
/// always line up, regardless of screen width.
struct ColumnLayout {
    let name: CGFloat
    let price: CGFloat
    let day: CGFloat
    let threeMonth: CGFloat
    let oneYear: CGFloat

    init(totalWidth: CGFloat) {
        name = totalWidth * 0.30
        price = totalWidth * 0.175
        day = totalWidth * 0.175
        threeMonth = totalWidth * 0.175
        oneYear = totalWidth * 0.175
    }

    func width(for column: SortColumn) -> CGFloat {
        switch column {
        case .name: return name
        case .price: return price
        case .day: return day
        case .threeMonth: return threeMonth
        case .oneYear: return oneYear
        }
    }
}
