import SwiftUI
import KursanzeigeKit

/// The sideways swipe of the chart page and the main page.
enum PageSwipe {
    /// The drag starts after 30 pt, so a tap on a button stays a tap.
    /// `PageStep` decides if the full drag is long enough for a step.
    static func gesture(onStep: @escaping (PageStep) -> Void) -> some Gesture {
        DragGesture(minimumDistance: 30).onEnded { value in
            guard let step = PageStep(swipeWidth: value.translation.width, height: value.translation.height) else { return }
            onStep(step)
        }
    }
}
