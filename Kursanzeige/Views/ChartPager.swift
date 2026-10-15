import SwiftUI
import KursanzeigeKit

/// The chart page, with "Vorheriger", "Nächster" and a sideways swipe
/// wired to the table order. It holds the shown chart itself: if
/// `MainView` swapped its presented item instead, the full-screen page
/// would close and open again on each step. The next chart keeps the
/// chosen range, and slides in from the side the step points to.
/// "Vorlesen" stays on across steps, and reads each new chart. The reader
/// lives as long as the open page, so each page starts with it off.
struct ChartPager: View {
    let mainViewModel: MainViewModel
    let onClose: () -> Void

    @State private var chart: InstrumentChartViewModel
    @State private var lastStep: PageStep = .next
    @State private var reader: ChartReader

    init(firstChart: InstrumentChartViewModel, mainViewModel: MainViewModel, speaker: Speaking, onClose: @escaping () -> Void) {
        _chart = State(initialValue: firstChart)
        _reader = State(initialValue: ChartReader(speaker: speaker))
        self.mainViewModel = mainViewModel
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            InstrumentChartView(
                viewModel: chart,
                onPrevious: neighbor(.previous) == nil ? nil : { show(.previous) },
                onNext: neighbor(.next) == nil ? nil : { show(.next) },
                isReadingAloud: reader.isOn,
                onReadAloud: { reader.toggle(shownText: spokenText) },
                onClose: onClose
            )
            .id(chart.id)
            .transition(.push(from: lastStep == .next ? .trailing : .leading))
        }
        .contentShape(Rectangle())
        .gesture(PageSwipe.gesture(onStep: show))
        .accessibilityScrollAction(scrollWithVoiceOver)
        .clipped()
        // A step, a range change or a fetched history gives a new text.
        .onChange(of: spokenText) { _, newText in reader.readIfOn(newText) }
        .onDisappear { reader.turnOff() }
    }

    private var spokenText: String? {
        chart.spokenSummary(rangeName: Formatting.chartRangeLabel(chart.range))
    }

    /// With VoiceOver on, a one-finger swipe moves the focus. A
    /// three-finger swipe to the left asks for the trailing edge.
    private func scrollWithVoiceOver(from edge: Edge) {
        switch edge {
        case .trailing: show(.next)
        case .leading: show(.previous)
        case .top, .bottom: break
        }
    }

    private func neighbor(_ step: PageStep) -> Instrument? {
        switch step {
        case .previous: mainViewModel.instrument(before: chart.instrument)
        case .next: mainViewModel.instrument(after: chart.instrument)
        }
    }

    /// Does nothing at the first or last row.
    private func show(_ step: PageStep) {
        guard let instrument = neighbor(step) else { return }
        let shownInstrument = chart.instrument
        lastStep = step
        // A separate update: the old chart must first take the new
        // direction, else it slides out to the wrong side.
        Task { @MainActor in
            // A second quick tap finds the step already done.
            guard chart.instrument == shownInstrument else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                chart = mainViewModel.makeChartViewModel(for: instrument, range: chart.range)
            }
        }
    }
}
