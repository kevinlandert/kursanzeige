import SwiftUI
import KursanzeigeKit

/// All sizes and colors live here so the "make everything bigger/bolder"
/// requirement (this app is for someone with low vision) stays a one-file
/// change instead of a hunt through every view.
enum Theme {
    // Colors chosen for contrast against the row backgrounds below, not just
    // hue: a value that rounds to 0.0 renders in `neutral`, and every percent
    // additionally carries an explicit +/− sign so color is never the only
    // signal. Darkened from an earlier, lighter pair once measured against
    // both row bands: #3A9A3A-ish green cleared only ~3.6:1 on white, under
    // the 4.5:1 minimum. These two clear 4.5:1 on both white and
    // `rowBackgroundOdd` (7.4:1 / 6.0:1 respectively).
    static let positive = Color(red: 0 / 255, green: 100 / 255, blue: 0 / 255)     // #006400
    static let negative = Color(red: 176 / 255, green: 0 / 255, blue: 0 / 255)     // #B00000
    static let neutral = Color.primary
    static let background = Color(uiColor: .systemBackground)
    static let headerBackground = Color(uiColor: .secondarySystemBackground)
    // `.separator` is intentionally translucent and easy to miss; `.opaqueSeparator`
    // is Apple's solid, more-visible counterpart while still adapting to dark mode.
    static let separator = Color(uiColor: .opaqueSeparator)
    // Alternating row bands: literal light-mode values chosen alongside
    // `positive`/`negative` above for specific measured contrast ratios, not
    // adaptive `UIColor`s -- dark mode isn't addressed by this pair and still
    // falls back to `background` until that's tackled separately.
    static let rowBackgroundEven = Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255)  // #FFFFFF
    static let rowBackgroundOdd = Color(red: 227 / 255, green: 232 / 255, blue: 240 / 255)   // #E3E8F0

    static let nameFontSize: CGFloat = 30
    static let nameFont = Font.system(size: nameFontSize, weight: .semibold)
    static let valueFont = Font.system(size: 30, weight: .bold).monospacedDigit()
    /// Just the leading +/− sign on a value cell: bigger and heavier than the
    /// digits so direction reads before color does.
    static let signFont = Font.system(size: 34, weight: .heavy).monospacedDigit()
    static let headerFont = Font.system(size: 26, weight: .bold)
    /// Thick dark-blue line for the chart overlay -- a color
    /// distinct from `positive`/`negative` so the line itself never reads
    /// as a signed value.
    static let chartLineColor = Color(red: 0 / 255, green: 51 / 255, blue: 153 / 255)  // #003399
    static let chartLineWidth: CGFloat = 12
    /// The high/low/current labels on the right axis and the start/end
    /// dates on the bottom axis: large and bold so they read at a glance,
    /// same rationale as every other number in this app.
    static let chartAxisFont = Font.system(size: 46, weight: .heavy).monospacedDigit()
    /// The instrument name. A long name shrinks to one line, so the chart
    /// keeps its height.
    static let chartTitleFont = Font.system(size: 128, weight: .bold)
    /// "Lädt …" and the error text in place of the chart.
    static let chartMessageFont = Font.system(size: 64, weight: .bold)
    /// The whole-range percent-change line below the chart -- deliberately
    /// the single biggest text on this screen, since it's the one-number
    /// summary of everything else on it.
    static let chartRangeChangeFont = Font.system(size: 84, weight: .heavy).monospacedDigit()
    static let chartCloseButtonSize: CGFloat = 44
    /// Extra gap between the chart's right-hand axis labels and the plot's
    /// own border, beyond Swift Charts' default spacing -- otherwise the
    /// high/low/current numbers sit almost flush against the box edge.
    static let chartAxisLabelMargin: CGFloat = 12
    /// Stroke width for the chart's axis lines/ticks/border -- noticeably
    /// heavier than `Theme.separator`'s usual hairline so the axis itself
    /// reads as clearly as the high/low/start/end labels next to it.
    static let chartAxisLineWidth: CGFloat = 2
    /// The plot's own border: darker and thicker again than the axis lines
    /// above, so the chart's outer edge is unmistakable at a glance.
    static let chartBorderColor = Color.primary
    static let chartBorderWidth: CGFloat = 3
    /// The two horizontal lines at the exact high/low close -- dashed so
    /// they read as "this is the line that explains that label" rather
    /// than blending into the regular automatic grid.
    static let chartExtremeLineColor = Color.primary
    static let chartExtremeLineWidth: CGFloat = 2.5
    static let chartExtremeLineDash: [CGFloat] = [8, 5]
    /// How close the current value needs to be to the high or low (as a
    /// fraction of the high-low range) before its label is left off the
    /// axis entirely, rather than drawn on top of that extreme's label.
    /// The labels are large, so they need a wide gap.
    static let chartCurrentValueMinSeparation: Double = 0.12
    /// "Vorheriger" and "Nächster" below the chart.
    static let chartNavigationFont = Font.system(size: 40, weight: .bold)
    /// A grey button on a grey field: it reads as "not available" at once.
    static let disabledButtonForeground = Color(uiColor: .secondaryLabel)
    static let groupButtonFont = Font.system(size: 24, weight: .semibold)
    static let refreshButtonFont = Font.system(size: 26, weight: .bold)
    static let statusFont = Font.system(size: 20, weight: .medium)
    static let timestampFont = Font.system(size: 24, weight: .semibold)
    static let progressFont = Font.system(size: 22, weight: .bold)

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
