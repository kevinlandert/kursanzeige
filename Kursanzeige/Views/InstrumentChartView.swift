import SwiftUI
import Charts
import KursanzeigeKit

/// Full-screen overlay opened by tapping a table row: the instrument's
/// close price over a chosen range, as a thick dark-blue line with the
/// highest and lowest value labeled directly on the right-hand axis --
/// large and bold, since this app is for someone with low vision -- plus
/// the current value in the same blue as the line (label only, no line of
/// its own), unless it's too close to the high or low for both labels to
/// fit without overlapping. Below the chart, a bold green/red line shows
/// the percent change across the whole shown range. The chart takes half
/// the screen. It shows the price
/// history of the last "Aktualisieren", so it opens without a network.
/// "Vorheriger" and "Nächster" at the bottom open the neighbor rows.
struct InstrumentChartView: View {
    let viewModel: InstrumentChartViewModel
    let onPrevious: (() -> Void)?
    let onNext: (() -> Void)?
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
                    .frame(height: geometry.size.height * 0.5)
                rangeChangeLabel
                Spacer(minLength: 0)
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
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .accessibilityIdentifier("chartTitle")
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: Theme.chartCloseButtonSize * 0.5, weight: .bold))
                    .frame(width: Theme.chartCloseButtonSize, height: Theme.chartCloseButtonSize)
                    .foregroundStyle(Color.primary)
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
                        .background(isActive ? Color.accentColor : Theme.headerBackground)
                        .foregroundStyle(isActive ? Color.white : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
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
                    .foregroundStyle(Color.primary)
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
        if let percent = rangeChangePercent {
            Text(Formatting.percent(percent))
                .font(Theme.chartRangeChangeFont)
                .foregroundStyle(Formatting.color(for: percent))
                .accessibilityLabel("Veränderung über den gewählten Zeitraum: \(Formatting.percent(percent))")
        }
    }

    private var rangeChangePercent: Double? {
        guard let first = viewModel.points.first?.close, let last = viewModel.points.last?.close, first != 0 else { return nil }
        return (last - first) / first * 100
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
        .chartYScale(domain: yAxisDomain)
    }

    /// A faint, regular grid, so a point in between is easier to place,
    /// plus bold lines and labels at the first and last date.
    @AxisContentBuilder
    private var xAxisMarks: some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
            AxisGridLine().foregroundStyle(Theme.separator.opacity(0.3))
        }
        AxisMarks(values: xAxisExtremes) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: Theme.chartAxisLineWidth)).foregroundStyle(Theme.separator)
            AxisTick(stroke: StrokeStyle(lineWidth: Theme.chartAxisLineWidth)).foregroundStyle(Theme.separator)
            AxisValueLabel(anchor: value.as(Date.self) == xAxisExtremes.first ? .topLeading : .topTrailing) {
                if let date = value.as(Date.self) {
                    Text(Formatting.chartAxisDate(date))
                        .font(Theme.chartAxisFont)
                        .foregroundStyle(Color.primary)
                }
            }
        }
    }

    /// The same faint grid as the x-axis, plus dashed lines and labels at
    /// the exact high and low. The current value gets a blue label only:
    /// no line, so it reads as "this is where we are now", not as a third
    /// rule that competes with the high/low pair.
    @AxisContentBuilder
    private var yAxisMarks: some AxisContent {
        AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
            AxisGridLine().foregroundStyle(Theme.separator.opacity(0.3))
            AxisTick().foregroundStyle(Theme.separator)
        }
        AxisMarks(position: .trailing, values: axisExtremes) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: Theme.chartExtremeLineWidth, dash: Theme.chartExtremeLineDash))
                .foregroundStyle(Theme.chartExtremeLineColor)
            priceAxisLabel(value, color: Color.primary)
        }
        AxisMarks(position: .trailing, values: currentValueAxisValue) { value in
            priceAxisLabel(value, color: Theme.chartLineColor)
        }
    }

    /// A price on the right axis, in the large axis font, with extra space
    /// between the label and the plot border.
    private func priceAxisLabel(_ value: AxisValue, color: Color) -> some AxisMark {
        AxisValueLabel(horizontalSpacing: Theme.chartAxisLabelMargin) {
            if let close = value.as(Double.self) {
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

    /// The most recent close, as a one-element (or empty) array for
    /// `AxisMarks(values:)` -- empty when it's too close to the high or
    /// low for its label to avoid overlapping that one.
    private var currentValueAxisValue: [Double] {
        guard let minClose = viewModel.minClose, let maxClose = viewModel.maxClose,
              let currentClose = viewModel.points.last?.close,
              isFarEnoughFromExtremes(currentClose, min: minClose, max: maxClose)
        else { return [] }
        return [currentClose]
    }

    /// Whether `value` sits far enough from both the high and the low
    /// (as a fraction of the high-low range) that its own axis label
    /// wouldn't land on top of that extreme's label.
    private func isFarEnoughFromExtremes(_ value: Double, min: Double, max: Double) -> Bool {
        let range = max - min
        guard range > 0 else { return false }
        let minimumSeparation = range * Theme.chartCurrentValueMinSeparation
        return abs(value - max) > minimumSeparation && abs(value - min) > minimumSeparation
    }

    /// A small margin above and below the shown close range -- without
    /// this, Swift Charts' default y-domain starts near zero, which
    /// squeezes the whole line into a thin band at the top of the plot
    /// (an index around 8'000 barely moves relative to a 0...8'000 axis).
    /// Scaling to the data's own range instead makes every wiggle visible
    /// and the half-screen-tall chart actually get used.
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
        onClose: {}
    )
}
