import SwiftUI
import KursanzeigeKit

/// The main page: the title bar with the refresh, the group selector, the table and
/// the bottom bar. Opens showing whatever was cached from the last
/// successful refresh -- "Aktualisieren" is a deliberate, visible action
/// rather than something that happens silently on launch. A sideways
/// swipe goes to the neighbor group. The bottom bar moves the yellow
/// cursor and reads the rows aloud. A tap on a row, or "Öffnen", opens the
/// chart page of that row.
struct MainView: View {
    let appModel: AppModel
    @State private var showingSettings = false
    /// Stored, so the choice stays after the app closes.
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.standard
    /// The columns that the voice reads. The settings change them.
    @AppStorage(SpokenColumns.storageKey) private var spokenColumns = SpokenColumns.standard

    private var viewModel: MainViewModel { appModel.viewModel }

    var body: some View {
        VStack(spacing: 0) {
            pageContent
                .padding(.horizontal, Theme.pageMargin)
                .padding(.vertical, 16)
                // Together with the table scroll: a swipe up or down still scrolls.
                .simultaneousGesture(PageSwipe.gesture(onStep: showNeighborGroup))
            BottomBar(
                reader: appModel.table.reader,
                page: "table",
                previousHint: ControlTexts.previousHint,
                nextHint: ControlTexts.nextHint,
                lastButton: openButton
            )
        }
        .background(Theme.background)
        // A new group, a new sort or new prices give the table new rows.
        .onChange(of: shownTable) { appModel.showRows(spokenColumns: spokenColumns) }
        .applyAppearance(appearance)
        .fullScreenCover(isPresented: $showingSettings, onDismiss: appModel.closeSettings) {
            SettingsView(appModel: appModel)
        }
        .fullScreenCover(item: chartPageBinding) { page in
            ChartPage(model: page, onClose: appModel.closeChart)
        }
    }

    private var pageContent: some View {
        VStack(spacing: 16) {
            topBar

            GroupSelectorView(selected: viewModel.selectedGroup) { group in
                viewModel.select(group)
            }

            PerformanceTableView(
                rows: viewModel.displayedRows,
                cursorRowId: appModel.table.reader.cursorRowId,
                sortColumn: viewModel.sortColumn,
                sortAscending: viewModel.sortAscending,
                oneYearMode: viewModel.oneYearMode,
                rangeMode: viewModel.rangeMode,
                onSort: { viewModel.toggleSort($0) },
                onSelect: { row in appModel.openChart(for: row.instrument) }
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.separator))
        }
    }

    /// The group, its rows and what the voice reads, together: two groups
    /// without rows also count as a change, and so does a new choice in
    /// the settings.
    private var shownTable: ShownTable {
        ShownTable(
            group: viewModel.selectedGroup, rows: viewModel.displayedRows, spokenColumns: spokenColumns,
            rangeMode: viewModel.rangeMode, oneYearMode: viewModel.oneYearMode
        )
    }

    private var openButton: BottomButtonContent {
        BottomButtonContent(
            title: ControlTexts.open, symbolName: "chart.xyaxis.line", placement: .trailing,
            look: .inverted, hint: ControlTexts.openHint, identifier: "table.openButton"
        ) {
            guard let instrument = appModel.table.openCursorRow() else { return }
            appModel.openChart(for: instrument)
        }
    }

    /// A close from the page itself sets the binding to nil.
    private var chartPageBinding: Binding<ChartPageModel?> {
        Binding(
            get: { appModel.chartPage },
            set: { newPage in
                if newPage == nil { appModel.closeChart() }
            }
        )
    }

    /// Does nothing at the first or the last group.
    private func showNeighborGroup(_ step: PageStep) {
        guard let group = viewModel.selectedGroup.neighbor(step) else { return }
        viewModel.select(group)
    }

    /// „Kurse“ over the time of the last refresh, with the buttons at the
    /// right, as in Schlagzeilen. The top of the buttons is in line with the
    /// top of „Kurse“.
    ///
    /// The progress and the failure count show in this bar, not in a row
    /// of their own. The bar keeps the space for the failure count when it
    /// is not visible. Thus the group buttons and the table never move.
    private var topBar: some View {
        HStack(alignment: .top) {
            titleLines
            Spacer()
            VStack(alignment: .trailing, spacing: Theme.titleLineSpacing) {
                HStack(spacing: Theme.topBarButtonGap) {
                    RefreshButton(isRefreshing: viewModel.isRefreshing) {
                        Task { await viewModel.refresh() }
                    }
                    SettingsButton {
                        appModel.openSettings()
                        showingSettings = true
                    }
                }
                // The buttons never break a word. The time gets a second line first.
                .fixedSize()
                if !viewModel.isRefreshing && !viewModel.failedFetches.isEmpty {
                    FailureStatusView(failedFetches: viewModel.failedFetches, totalCount: viewModel.totalInstrumentCount)
                }
            }
        }
        .frame(minHeight: Theme.titleBarHeight, alignment: .top)
    }

    /// During a refresh, the progress shows in place of the time. The time
    /// is old during a refresh, and the new time shows after it. On a narrow
    /// screen, the time can take two lines. The hidden time keeps its space
    /// during a refresh, so the bar keeps its height.
    private var titleLines: some View {
        VStack(alignment: .leading, spacing: Theme.titleLineSpacing) {
            Text("Kurse")
                .font(Theme.pageTitleFont)
                .foregroundStyle(Theme.text)
                // The line is as high as the font size, as in Schlagzeilen.
                .padding(.vertical, -Theme.pageTitleTrim)
                .accessibilityAddTraits(.isHeader)
            ZStack(alignment: .topLeading) {
                Text(UpdateTexts.updateLine(lastUpdate: viewModel.lastUpdated))
                    .font(Theme.timestampFont)
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(viewModel.isRefreshing ? 0 : 1)
                    .accessibilityHidden(viewModel.isRefreshing)
                    .accessibilityLabel(UpdateTexts.updateLabel(lastUpdate: viewModel.lastUpdated))
                    .accessibilityIdentifier("updateLine")
                if viewModel.isRefreshing {
                    RefreshProgressView(progress: viewModel.progress)
                }
            }
        }
    }
}

/// The shown group with its rows, in the order of the table, and what the
/// voice reads of each row.
private struct ShownTable: Equatable {
    let group: MarketGroup
    let rows: [InstrumentRow]
    let spokenColumns: SpokenColumns
    let rangeMode: RangeMode
    let oneYearMode: OneYearMode
}

#Preview {
    MainView(appModel: AppModel())
}
