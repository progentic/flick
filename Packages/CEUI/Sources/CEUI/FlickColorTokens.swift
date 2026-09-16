/// Adaptive sRGB tokens. Kept independent of SwiftUI so contrast is testable.
struct FlickColorTokens: Sendable {
    let canvas: UInt32
    let ink: UInt32
    let secondary: UInt32
    let ember: UInt32
    let onEmber: UInt32
    let outline: UInt32
    var error: UInt32 { ink == Self.light.ink ? 0x9D2020 : 0xFFB4AB }
    var errorSurface: UInt32 { ink == Self.light.ink ? 0xFFF1EF : 0x321B19 }

    static let light = FlickColorTokens(canvas: 0xFAFAF8, ink: 0x161310, secondary: 0x595147,
                                        ember: 0xA43212, onEmber: 0xFFFFFF, outline: 0x706559)
    static let dark = FlickColorTokens(canvas: 0x161310, ink: 0xF4F1EA, secondary: 0xD2C9BB,
                                       ember: 0xFF9B78, onEmber: 0x161310, outline: 0xB6AA99)
    static let highContrastLight = FlickColorTokens(canvas: light.canvas, ink: light.ink,
                                                    secondary: light.secondary, ember: 0x912B0D,
                                                    onEmber: light.onEmber, outline: light.secondary)
    static let highContrastDark = dark
}
