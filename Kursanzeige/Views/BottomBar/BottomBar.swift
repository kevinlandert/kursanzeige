import KursanzeigeKit
import SwiftUI

/// The bar at the bottom of the table and of the chart page, as in
/// Schlagzeilen: the status line over the buttons Vorherige · Vorlesen/Pause
/// · Nächste and a last button. Pause replaces Vorlesen while the app reads.
/// The last button is Öffnen on the table and Schliessen on the chart page.
struct BottomBar: View {
    let reader: ListReader
    /// "table" or "chart". The table stays under the chart page, so each
    /// bar needs its own identifiers for a UI test.
    let page: String
    let previousHint: String
    let nextHint: String
    let lastButton: BottomButtonContent

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.text)
                .frame(height: Theme.bottomBarRuleWidth)
            VStack(spacing: Theme.bottomBarSpacing) {
                StatusLine(text: reader.statusText, style: reader.statusStyle)
                    .accessibilityIdentifier("\(page).statusLine")
                // All four buttons take the same layout, so the bar stays calm.
                ViewThatFits(in: .horizontal) {
                    makeButtons(layout: .inline)
                    makeButtons(layout: .stacked)
                }
            }
            .padding(.horizontal, Theme.bottomBarHorizontalPadding)
            .padding(.top, Theme.bottomBarTopPadding)
            .padding(.bottom, Theme.bottomBarBottomPadding)
        }
        .background(Theme.background)
    }

    private func makeButtons(layout: LabelLayout) -> some View {
        EqualColumnsLayout(spacing: Theme.bottomButtonSpacing) {
            BottomBarButton(content: previousButton, layout: layout)
            BottomBarButton(content: readingButton, layout: layout)
            BottomBarButton(content: nextButton, layout: layout)
            BottomBarButton(content: lastButton, layout: layout)
        }
    }

    private var previousButton: BottomButtonContent {
        BottomButtonContent(
            title: ControlTexts.previous, symbolName: "backward.end", placement: .leading,
            look: .outlined, hint: previousHint, identifier: "\(page).previousButton", action: { reader.showPrevious() }
        )
    }

    /// Vorlesen, or Pause while the app reads. One identifier, so a UI test
    /// finds the button in both states.
    private var readingButton: BottomButtonContent {
        BottomButtonContent(
            title: reader.isReading ? ControlTexts.pause : ControlTexts.startReading,
            symbolName: reader.isReading ? "pause.fill" : "play.fill",
            placement: .leading,
            look: .primary,
            hint: reader.isReading ? ControlTexts.pauseHint : ControlTexts.startReadingHint,
            identifier: "\(page).readingButton",
            action: reader.toggleReading
        )
    }

    private var nextButton: BottomButtonContent {
        BottomButtonContent(
            title: ControlTexts.next, symbolName: "forward.end", placement: .trailing,
            look: .outlined, hint: nextHint, identifier: "\(page).nextButton", action: { reader.showNext() }
        )
    }
}
