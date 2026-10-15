import SwiftUI
import UIKit
import KursanzeigeKit

extension Color {
    /// A color that takes its value from `Palette.light` or `Palette.dark`.
    /// iOS selects the value again when the appearance changes.
    static func palette(_ color: KeyPath<Palette, RGBColor>) -> Color {
        Color(uiColor: UIColor { traits in
            let palette = traits.userInterfaceStyle == .dark ? Palette.dark : Palette.light
            return UIColor(palette[keyPath: color])
        })
    }
}

extension UIColor {
    convenience init(_ color: RGBColor) {
        self.init(red: CGFloat(color.red) / 255, green: CGFloat(color.green) / 255, blue: CGFloat(color.blue) / 255, alpha: 1)
    }
}
