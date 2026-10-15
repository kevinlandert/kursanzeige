import SwiftUI
import Charts
import KursanzeigeKit

/// Full-screen overlay opened by tapping a table row: the instrument's
/// close price over a chosen range, as a thick yellow line with the
/// highest and lowest value labeled directly on the right-hand axis --
/// large and bold, since this app is for someone with low vision -- plus
/// the current value in the same color as the line (label only, no line of
/// its own), unless it's too close to the high or low for both labels to
/// fit without overlapping. Below the chart, a bold green/red line shows
/// the percent change across the whole shown range. The chart takes 45 %
/// of the screen, so the title keeps its full size. It shows the price
/// history of the last "Aktualisieren", so it opens without a network.
/// "Vorlesen" reads the chart aloud. "Vorheriger" and "Nächster" at the
/// bottom open the neighbor rows.
struct InstrumentChartView: View {
    let viewModel: InstrumentChartViewModel
    let onPrevious: (() -> Void)?
    let onNext: (() -> Void)?
    let isReadingAloud: Bool
    let onReadAloud: () -> Void
    let onClose: () -> Void

    private var group: MarketGroup { viewModel.instrument.group }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                header
                rangeSelector
                content
                    // A fixed height, not just a minimum -- Swift Charts
                    // doesn't reliably stretch its plot area to fill an
                    // open-ended `maxHeight: .infinity` proposal, which
                    // left a large blank gap below the plot with the
                    // x-axis labels stranded at the very bottom of the
                    // screen instead of right under the chart.
                    .frame(height: geometry.size.height * Theme.chartHeightShare)
                rangeChangeLabel
                Spacer(minLength: 0)
                ReadAloudButton(isOn: isReadingAloud, action: onReadAloud)
                ChartNavigationButtons(onPrevious: onPrevious, onNext: onNext)
            }
            .padding(Theme.pageMargin)
            .background(Theme.background)
        }
        // Keyed by the instrument, so a new instrument also gets its fetch
        // if a caller swaps the view model without a new view identity.
        .task(id: viewModel.id) { await viewModel.load() }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(viewModel.instrument.name)
                .font(Theme.chartTitleFont)
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .accessibilityIdentifier("chartTitle")
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: Theme.chartCloseButtonSize * 0.5, weight: .bold))
                    .frame(width: Theme.chartCloseButtonSize, height: Theme.chartCloseButtonSize)
                    .foregroundStyle(Theme.text)
            }
            .accessibilityLabel("Schliessen")
        }
    }

    /// The four range buttons. Picking one cuts that span from the
    /// stored history at once (see `InstrumentChartViewModel.select`).
    private var rangeSelector: some View {
        HStack(spacing: 10) {
            ForEach(ChartRange.allCases, id: \.self) { range in
                let isActive = range == viewModel.range
                Button {
                    viewModel.select(range)
                } label: {
                    Text(Formatting.chartRangeLabel(range))
                        .font(Theme.groupButtonFont)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .choiceButtonLook(isSelected: isActive)
                }
                .buttonStyle(.plain)
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
                .foregroundStyle(Formatting.color(for: percent))
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
                .foregroundStyle(Theme.chartLineColor)
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

    /// A faint, regular grid, so a point in between is easier to place,
    /// plus the first and the last date below the ends of the line. The
    /// dates have no grid line or tick: the line ends show their place.
    @AxisContentBuilder
    private var xAxisMarks: some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
            AxisGridLine().foregroundStyle(Theme.separator.opacity(0.3))
        }
        AxisMarks(values: xAxisExtremes) { value in
            AxisValueLabel(anchor: value.as(Date.self) == xAxisExtremes.first ? .topLeading : .topTrailing) {
                if let date = value.as(Date.self) {
                    Text(Formatting.chartAxisDate(date))
                        .font(Theme.chartAxisFont)
                        .foregroundStyle(Theme.text)
                }
            }
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
            priceAxisLabel(viewModel.points.last?.close, color: Theme.chartLineColor)
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

    /// The first and last date in the shown range -- the x-axis always
    /// labels exactly these two, at the plot's left and right edges,
    /// rather than whatever month boundary Swift Charts would pick
    /// automatically.
    private var xAxisExtremes: [Date] {
        guard let first = viewModel.points.first?.date, let last = viewModel.points.last?.date, first != last else {
            return viewModel.points.first.map { [$0.date] } ?? []
        }
        return [first, last]
    }
}

#Preview {
    InstrumentChartView(
        viewModel: MainViewModel().makeChartViewModel(for: Instrument(symbol: "NESN.SW", name: "Nestlé", group: .switzerland)),
        onPrevious: nil,
        onNext: {},
        isReadingAloud: false,
        onReadAloud: {},
        onClose: {}
    )
}
