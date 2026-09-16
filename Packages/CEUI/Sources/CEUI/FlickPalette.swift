#if os(iOS)
import SwiftUI

struct FlickPalette {
    let dark: Bool
    let highContrast: Bool

    private var tokens: FlickColorTokens {
        if dark { return highContrast ? .highContrastDark : .dark }
        return highContrast ? .highContrastLight : .light
    }

    var canvas: Color { color(tokens.canvas) }
    var ink: Color { color(tokens.ink) }
    var secondary: Color { color(tokens.secondary) }
    var ember: Color { color(tokens.ember) }
    var onEmber: Color { color(tokens.onEmber) }
    var outline: Color { color(tokens.outline) }
    var error: Color { color(tokens.error) }
    var errorSurface: Color { color(tokens.errorSurface) }

    private func color(_ value: UInt32) -> Color {
        return Color(.sRGB, red: Double((value >> 16) & 255) / 255,
                     green: Double((value >> 8) & 255) / 255,
                     blue: Double(value & 255) / 255, opacity: 1)
    }
}
#endif
