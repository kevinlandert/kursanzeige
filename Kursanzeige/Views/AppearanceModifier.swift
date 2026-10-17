import KursanzeigeKit
import SwiftUI
import UIKit

extension View {
    /// Gives the window of this view the style of the Erscheinungsbild.
    /// „Wie iPad“ sets no style, so the app follows the iPad. Each
    /// full-screen cover is in the same window, so it takes the style too.
    /// `preferredColorScheme` is not used: a change from `.dark` to nil
    /// keeps the app dark.
    func applyAppearance(_ appearance: Appearance) -> some View {
        background(WindowStyleSetter(style: appearance.interfaceStyle))
    }
}

/// An empty view that sets the style of its window.
private struct WindowStyleSetter: UIViewRepresentable {
    let style: UIUserInterfaceStyle

    func makeUIView(context: Context) -> WindowStyleView {
        WindowStyleView()
    }

    func updateUIView(_ view: WindowStyleView, context: Context) {
        view.style = style
    }
}

/// The view has no window at its first update, so it also sets the style
/// when it comes into a window.
private final class WindowStyleView: UIView {
    var style: UIUserInterfaceStyle = .unspecified {
        didSet { applyStyle() }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyStyle()
    }

    private func applyStyle() {
        window?.overrideUserInterfaceStyle = style
    }
}

private extension Appearance {
    /// The style that the app forces. `.unspecified` lets the iPad decide.
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: .light
        case .dark: .dark
        case .device: .unspecified
        }
    }
}
