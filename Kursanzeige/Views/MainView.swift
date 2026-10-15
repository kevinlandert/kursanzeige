import SwiftUI
import KursanzeigeKit

/// The whole app is this one screen: a status/refresh bar, the group
/// selector, and the table. Opens showing whatever was cached from the
/// last successful refresh -- "Aktualisieren" is a deliberate, visible
/// action rather than something that happens silently on launch.
struct MainView: View {
    @State private var viewModel = MainViewModel()
    @State private var showingSettings = false
    /// Set by a row tap. Created once per tap, so the chart's history file
    /// is read once, not on every re-render of this view.
    @State private var chartViewModel: InstrumentChartViewModel?

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
                onSelect: { chartViewModel = viewModel.makeChartViewModel(for: $0.instrument) }
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.separator))
        }
        .padding(.horizontal, Theme.pageMargin)
        .padding(.vertical, 16)
        .background(Theme.background)
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel)
        }
        .fullScreenCover(item: $chartViewModel) { chart in
            InstrumentChartView(viewModel: chart) { chartViewModel = nil }
        }
    }

    /// The refresh-progress bar and the post-refresh failure count both
    /// live here now, next to the settings button, instead of as a row
    /// between the group selector and the table -- that row only existed
    /// while refreshing or while there were failures, so its
    /// appearance/disappearance shifted the group selector and table down
    /// and back up. `topBar` never gains or loses a row, so nothing moves.
    ///
    /// The bar is pinned to a fixed height and centered (not
    /// `.firstTextBaseline`): several of these children aren't text, so
    /// baseline alignment falls back to each one's bottom edge, and that
    /// fallback shifted as different non-text children appeared/disappeared.
    /// A fixed height sidesteps that entirely.
    private var topBar: some View {
        HStack(alignment: .center) {
            Text(Formatting.asOf(viewModel.lastUpdated))
                .font(Theme.timestampFont)
                .foregroundStyle(Color.primary)
            Spacer()
            if viewModel.isRefreshing {
                RefreshProgressView(progress: viewModel.progress)
            } else if !viewModel.failedFetches.isEmpty {
                FailureStatusView(failedFetches: viewModel.failedFetches, totalCount: viewModel.totalInstrumentCount)
            }
            SettingsButton {
                showingSettings = true
            }
            RefreshButton(isRefreshing: viewModel.isRefreshing) {
                Task { await viewModel.refresh() }
            }
        }
        .frame(height: Theme.topBarHeight)
    }
}

#Preview {
    MainView()
}
