import SwiftUI
import KursanzeigeKit

/// The chart page: the chart of one row, and the bottom bar with
/// Vorherige · Vorlesen/Pause · Nächste · Schliessen. Vorherige, Nächste
/// and a sideways swipe show the chart of the neighbor row in the table
/// order, and read it. The next chart keeps the chosen range, and slides
/// in from the side the step points to. The bar stays in place.
struct ChartPage: View {
    let model: ChartPageModel
    let onClose: () -> Void

    /// The chart on screen. It follows `model.chart` one update later: the
    /// old chart must first take the new direction, else it slides out to
    /// the wrong side.
    @State private var shownChart: InstrumentChartViewModel
    @State private var slideStep = PageStep.next

    init(model: ChartPageModel, onClose: @escaping () -> Void) {
        self.model = model
        self.onClose = onClose
        _shownChart = State(initialValue: model.chart)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                InstrumentChartView(viewModel: shownChart, onSelectRange: model.select)
                    .id(shownChart.id)
                    .transition(.push(from: slideStep == .next ? .trailing : .leading))
            }
            .contentShape(Rectangle())
            .gesture(PageSwipe.gesture(onStep: model.show))
            .accessibilityScrollAction(scrollWithVoiceOver)
            .clipped()
            BottomBar(
                reader: model.reader,
                page: "chart",
                previousHint: ControlTexts.previousChartHint,
                nextHint: ControlTexts.nextChartHint,
                lastButton: closeButton
            )
        }
        .background(Theme.background)
        .onChange(of: model.chart.id) { showNewChart() }
    }

    private var closeButton: BottomButtonContent {
        BottomButtonContent(
            title: ControlTexts.close, symbolName: "xmark", placement: .trailing,
            look: .inverted, hint: ControlTexts.closeHint, identifier: "chart.closeButton", action: onClose
        )
    }

    private func showNewChart() {
        slideStep = model.lastStep
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.3)) {
                shownChart = model.chart
            }
        }
    }

    /// With VoiceOver on, a one-finger swipe moves the focus. A
    /// three-finger swipe to the left asks for the trailing edge.
    private func scrollWithVoiceOver(from edge: Edge) {
        switch edge {
        case .trailing: model.show(.next)
        case .leading: model.show(.previous)
        case .top, .bottom: break
        }
    }
}
