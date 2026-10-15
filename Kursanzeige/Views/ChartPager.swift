import SwiftUI
import KursanzeigeKit

/// The chart page, with "Vorheriger" and "Nächster" wired to the table
/// order. It holds the shown chart itself: if `MainView` swapped its
/// presented item instead, the full-screen page would close and open
/// again on each tap. The next chart keeps the chosen range.
struct ChartPager: View {
    let mainViewModel: MainViewModel
    let onClose: () -> Void

    @State private var chart: InstrumentChartViewModel

    init(firstChart: InstrumentChartViewModel, mainViewModel: MainViewModel, onClose: @escaping () -> Void) {
        _chart = State(initialValue: firstChart)
        self.mainViewModel = mainViewModel
        self.onClose = onClose
    }

    var body: some View {
        InstrumentChartView(
            viewModel: chart,
            onPrevious: showChartAction(for: mainViewModel.instrument(before: chart.instrument)),
            onNext: showChartAction(for: mainViewModel.instrument(after: chart.instrument)),
            onClose: onClose
        )
    }

    /// `nil` when there is no such row, which greys the button out.
    private func showChartAction(for instrument: Instrument?) -> (() -> Void)? {
        guard let instrument else { return nil }
        return {
            chart = mainViewModel.makeChartViewModel(for: instrument, range: chart.range)
        }
    }
}
