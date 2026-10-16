import SwiftUI
import KursanzeigeKit

/// The whole app is this one screen: a status/refresh bar, the group
/// selector, and the table. Opens showing whatever was cached from the
/// last successful refresh -- "Aktualisieren" is a deliberate, visible
/// action rather than something that happens silently on launch.
/// A sideways swipe goes to the neighbor group. "Vorlesen" at the bottom
/// reads the table.
struct MainView: View {
    @State private var viewModel = MainViewModel()
    @State private var showingSettings = false
    /// Set by a row tap. Created once per tap, so the chart's history file
    /// is read once, not on every re-render of this view.
    @State private var chartViewModel: InstrumentChartViewModel?
    /// One voice for the full app life. See `SynthesizerSpeaker`.
    @State private var speaker: SynthesizerSpeaker
    /// "Vorlesen" of the table. It uses the same voice as the chart page.
    @State private var tableReader: PageReader
    /// Stored, so the choice stays after the app closes.
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.light

    init() {
        let speaker = SynthesizerSpeaker()
        _speaker = State(initialValue: speaker)
        _tableReader = State(initialValue: PageReader(speaker: speaker))
    }

    var body: some View {
        VStack(spacing: 16) {
            topBar

            GroupSelectorView(selected: viewModel.selectedGroup) { group in
                viewModel.select(group)
            }

            PerformanceTableView(
                rows: viewModel.displayedRows,
                sortColumn: viewModel.sortColumn,
                sortAscending: viewModel.sortAscending,
                oneYearMode: viewModel.oneYearMode,
                rangeMode: viewModel.rangeMode,
                onSort: { viewModel.toggleSort($0) },
                onSelect: { row in
                    tableReader.turnOff()
                    chartViewModel = viewModel.makeChartViewModel(for: row.instrument)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.separator))

            ReadAloudButton(isOn: tableReader.isOn, identifier: "tableReadAloud") {
                tableReader.toggle(shownText: viewModel.spokenTable)
            }
        }
        .padding(.horizontal, Theme.pageMargin)
        .padding(.vertical, 16)
        .background(Theme.background)
        // Together with the table scroll: a swipe up or down still scrolls.
        .simultaneousGesture(PageSwipe.gesture(onStep: showNeighborGroup))
        // Not on each new price: during a refresh, the voice would start
        // again after each fetch.
        .onChange(of: tableOrder) { tableReader.readIfOn(viewModel.spokenTable) }
        .preferredColorScheme(appearance == .dark ? .dark : .light)
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel)
        }
        .fullScreenCover(item: $chartViewModel) { chart in
            ChartPager(firstChart: chart, mainViewModel: viewModel, speaker: speaker) { chartViewModel = nil }
        }
    }

    /// A new group or a new sort gives a new table text.
    private var tableOrder: TableOrder {
        TableOrder(group: viewModel.selectedGroup, sortColumn: viewModel.sortColumn, sortAscending: viewModel.sortAscending)
    }

    /// Does nothing at the first or the last group.
    private func showNeighborGroup(_ step: PageStep) {
        guard let group = viewModel.selectedGroup.neighbor(step) else { return }
        viewModel.select(group)
    }

    /// The progress and the failure count show in this bar, not in a row
    /// of their own. Thus the group buttons and the table never move.
    ///
    /// During a refresh, the progress shows in place of the date. The bar
    /// does not have space for both next to the buttons. The date is old
    /// during a refresh, and the new date shows after it.
    ///
    /// The bar has a fixed height and centers its items. A text baseline
    /// does not work: for an item without text, the baseline is the
    /// bottom edge, and that edge changes when an item comes or goes.
    private var topBar: some View {
        HStack(alignment: .center) {
            if viewModel.isRefreshing {
                RefreshProgressView(progress: viewModel.progress)
            } else {
                Text(Formatting.asOf(viewModel.lastUpdated))
                    .font(Theme.timestampFont)
                    .foregroundStyle(Theme.text)
            }
            Spacer()
            if !viewModel.isRefreshing && !viewModel.failedFetches.isEmpty {
                FailureStatusView(failedFetches: viewModel.failedFetches, totalCount: viewModel.totalInstrumentCount)
            }
            AppearanceButton(appearance: appearance) {
                appearance = appearance.toggled
            }
            SettingsButton {
                tableReader.turnOff()
                showingSettings = true
            }
            .padding(.leading, Theme.topBarButtonGap)
            RefreshButton(isRefreshing: viewModel.isRefreshing) {
                Task { await viewModel.refresh() }
            }
            .padding(.leading, Theme.topBarButtonGap)
        }
        .frame(height: Theme.topBarHeight)
    }
}

/// The shown group and its sort, without the prices.
private struct TableOrder: Equatable {
    let group: MarketGroup
    let sortColumn: SortColumn
    let sortAscending: Bool
}

#Preview {
    MainView()
}
