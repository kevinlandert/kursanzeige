import Foundation

/// A screen color as 8-bit red, green and blue values. The library cannot
/// use SwiftUI, so the tests check the contrast with this type.
public struct RGBColor: Sendable, Equatable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8

    /// `hex` is 0xRRGGBB, as in a design tool.
    public init(hex: UInt32) {
        red = UInt8((hex >> 16) & 0xFF)
        green = UInt8((hex >> 8) & 0xFF)
        blue = UInt8(hex & 0xFF)
    }

    /// The WCAG 2 contrast ratio, from 1 (no contrast) to 21 (black on
    /// white). The order of the two colors has no effect.
    public func contrastRatio(to other: RGBColor) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// The WCAG 2 relative luminance: 0 for black, 1 for white.
    var relativeLuminance: Double {
        0.2126 * Self.linearValue(red) + 0.7152 * Self.linearValue(green) + 0.0722 * Self.linearValue(blue)
    }

    /// Removes the sRGB gamma from one channel.
    private static func linearValue(_ channel: UInt8) -> Double {
        let value = Double(channel) / 255
        return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
}
