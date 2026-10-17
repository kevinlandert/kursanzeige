import SwiftUI
import Charts
import KursanzeigeKit

/// The chart of one instrument, on the chart page: the instrument's close
/// price over a chosen range, as a thick line with the highest and lowest
/// value labeled directly on the right-hand axis -- large and bold, since
/// this app is for someone with low vision -- plus the current value in
/// the same color as the line (label only, no line of its own). Near the
/// high or low, the current value label moves away. Below the chart, a
/// bold line shows the percent change across the whole shown range. The
/// line, the current value and the change are green for a rise and red
/// for a fall, in the same color, so the direction shows three times. It shows the price
/// history of the last "Aktualisieren", so it opens without a network.
/// The currency of a stock, an ETF or a future shows next to the title.
///
/// Portrait and landscape have the same order: the title line, the range
/// buttons, the chart and the change. The title line has a fixed height,
/// so a long name or a missing currency never moves the buttons. The
/// chart keeps a ratio from 1.5 to 2 (see `ChartShape`), so a move looks
/// about as steep in both orientations. The change follows right below it.
struct InstrumentChartView: View {
    let viewModel: InstrumentChartViewModel
    let onSelectRange: (ChartRange) -> Void

    private var group: MarketGroup { viewModel.instrument.group }

    var body: some View {
        VStack(spacing: 16) {
            header
                .frame(height: Theme.chartTitleRowHeight, alignment: .leading)
            rangeSelector
            chartArea
        }
        .padding(Theme.pageMargin)
        .background(Theme.background)
        // Keyed by the instrument, so a new instrument also gets its fetch
        // if a caller swaps the view model without a new view identity.
        .task(id: viewModel.id) { await viewModel.load() }
    }

    /// The currency follows the name on the same line. A long name gets
    /// smaller, so the line keeps its height.
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            title
            // The full code always shows: a long name gets smaller first.
            currencyLabel
                .padding(.leading, Theme.chartCurrencyGap)
            Spacer(minLength: 0)
        }
    }

    /// The chart in the size of `ChartShape`, centered, with the change
    /// below it. The free space goes below the change.
    private var chartArea: some View {
        GeometryReader { geometry in
            let size = ChartShape.fit(
                width: geometry.size.width,
                height: geometry.size.height - Theme.chartRangeChangeHeight - Theme.chartAreaSpacing
            )
            VStack(spacing: Theme.chartAreaSpacing) {
                content
                    .frame(width: size.width, height: size.height)
                rangeChangeLabel
                    .frame(height: Theme.chartRangeChangeHeight)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// The direction over the shown range: a rise, a fall or no change.
    private var trend: ValueTone {
        Formatting.tone(for: viewModel.rangeChangePercent)
    }

    private var title: some View {
        Text(viewModel.instrument.name)
            .font(Theme.chartTitleFont)
            .foregroundStyle(Theme.text)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .accessibilityIdentifier("chartTitle")
    }

    @ViewBuilder
    private var currencyLabel: some View {
        if let currency = viewModel.currency {
            Text(currency)
                .font(Theme.chartCurrencyFont)
                .foregroundStyle(Theme.mutedText)
                .fixedSize()
        }
    }

    /// The four range buttons. Picking one cuts that span from the
    /// stored history at once (see `InstrumentChartViewModel.select`).
    private var rangeSelector: some View {
        HStack(spacing: 10) {
            ForEach(ChartRange.allCases, id: \.self) { range in
                let isActive = range == viewModel.range
                Button {
                    onSelectRange(range)
                } label: {
                    Text(range.displayName)
                        .font(Theme.groupButtonFont)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, Theme.choiceButtonTextInset)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .choiceButtonLook(isSelected: isActive)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(range.spokenName)
                .accessibilityAddTraits(isActive ? [.isSelected] : [])
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            Spacer()
            VStack(spacing: 16) {
                ProgressView().controlSize(.large)
                Text("Lädt …")
                    .font(Theme.chartMessageFont)
                    .foregroundStyle(Theme.text)
            }
            Spacer()
        } else if let errorMessage = viewModel.errorMessage {
            Spacer()
            errorView(errorMessage)
            Spacer()
        } else {
            chart
        }
    }

    /// The change from the first to the last point on screen -- the whole
    /// shown range's performance, not a fixed period, so it always
    /// matches whichever of the four range buttons is active.
    @ViewBuilder
    private var rangeChangeLabel: some View {
        if let percent = viewModel.rangeChangePercent {
            Text(Formatting.percent(percent))
                .font(Theme.chartRangeChangeFont)
                .foregroundStyle(trend.color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityLabel("Veränderung über den gewählten Zeitraum: \(Formatting.percent(percent))")
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .font(Theme.chartMessageFont)
                .multilineTextAlignment(.center)
            Button("Erneut versuchen") {
                Task { await viewModel.load() }
            }
            .font(Theme.headerFont)
        }
    }

    private var chart: some View {
        Chart(viewModel.points, id: \.date) { point in
            LineMark(x: .value("Datum", point.date), y: .value("Kurs", point.close))
                .foregroundStyle(trend.color)
                .lineStyle(StrokeStyle(lineWidth: Theme.chartLineWidth, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.linear)
        }
        .chartXAxis { xAxisMarks }
        .chartYAxis { yAxisMarks }
        .chartPlotStyle { plotArea in
            plotArea.border(Theme.chartBorderColor, width: Theme.chartBorderWidth)
        }
        .chartXScale(range: .plotDimension(padding: Theme.chartLineInset))
        .chartYScale(domain: yAxisDomain)
    }

    /// A faint, regular grid, so a point in between is easier to place.
    /// No dates: the selected range button tells the period.
    private var xAxisMarks: some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
            AxisGridLine().foregroundStyle(Theme.separator.opacity(0.3))
        }
    }

    /// The same faint grid as the x-axis, plus dashed lines and labels at
    /// the exact high and low. The current price gets a label in the line
    /// color, except for a flat line. It gets no line: a third line would
    /// compete with the high and low lines. Near the high or low, the
    /// label moves away.
    @AxisContentBuilder
    private var yAxisMarks: some AxisContent {
        AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
            AxisGridLine().foregroundStyle(Theme.separator.opacity(0.3))
            AxisTick().foregroundStyle(Theme.separator)
        }
        AxisMarks(position: .trailing, values: axisExtremes) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: Theme.chartExtremeLineWidth, dash: Theme.chartExtremeLineDash))
                .foregroundStyle(Theme.chartExtremeLineColor)
            priceAxisLabel(value.as(Double.self), color: Theme.text)
        }
        AxisMarks(position: .trailing, values: currentPriceLabelPosition) { _ in
            priceAxisLabel(viewModel.points.last?.close, color: trend.color)
        }
    }

    /// A price on the right axis, in the large axis font, with extra space
    /// between the label and the plot border.
    private func priceAxisLabel(_ price: Double?, color: Color) -> some AxisMark {
        AxisValueLabel(horizontalSpacing: Theme.chartAxisLabelMargin) {
            if let close = price {
                Text(Formatting.price(close, group: group))
                    .font(Theme.chartAxisFont)
                    .foregroundStyle(color)
            }
        }
    }

    /// The exact lowest and highest close in the shown range -- the two
    /// values the right-hand axis must label, regardless of where Swift
    /// Charts' automatic grid lines happen to land.
    private var axisExtremes: [Double] {
        guard let minClose = viewModel.minClose, let maxClose = viewModel.maxClose else { return [] }
        return [minClose, maxClose]
    }

    /// The place of the current price label, as a list of one value for
    /// `AxisMarks(values:)`. Empty without data or for a flat line.
    private var currentPriceLabelPosition: [Double] {
        guard let low = viewModel.minClose, let high = viewModel.maxClose,
              let current = viewModel.points.last?.close,
              let position = CurrentPriceLabel.axisValue(current: current, low: low, high: high, minimumGapShare: Theme.chartCurrentPriceLabelGapShare)
        else { return [] }
        return [position]
    }

    /// A small margin above and below the shown close range -- without
    /// this, Swift Charts' default y-domain starts near zero, which
    /// squeezes the whole line into a thin band at the top of the plot
    /// (an index around 8'000 barely moves relative to a 0...8'000 axis).
    /// Scaling to the data's own range instead makes every wiggle visible
    /// and the tall chart actually get used.
    private var yAxisDomain: ClosedRange<Double> {
        guard let minClose = viewModel.minClose, let maxClose = viewModel.maxClose, minClose < maxClose else {
            let only = viewModel.minClose ?? 0
            return (only - 1)...(only + 1)
        }
        let margin = (maxClose - minClose) * 0.1
        return (minClose - margin)...(maxClose + margin)
    }
}

#Preview {
    InstrumentChartView(
        viewModel: MainViewModel().makeChartViewModel(for: Instrument(symbol: "NESN.SW", name: "Nestlé", group: .switzerland)),
        onSelectRange: { _ in }
    )
}
