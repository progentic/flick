import Foundation
import Testing
@testable import CEUI

struct ColorContrastTests {
    @Test(arguments: [FlickColorTokens.light, .dark])
    func standardTokensMeetAA(_ tokens: FlickColorTokens) {
        check(tokens, textThreshold: 4.5)
    }

    @Test(arguments: [FlickColorTokens.highContrastLight, .highContrastDark])
    func enhancedTextMeetsSevenToOne(_ tokens: FlickColorTokens) {
        check(tokens, textThreshold: 7)
    }

    @Test func calculationRejectsTheOldDraftPair() {
        #expect(ratio(0xA9A195, 0xFFFFFF) < 4.5)
        #expect(abs(ratio(0x000000, 0xFFFFFF) - 21) < 0.001)
    }

    private func check(_ tokens: FlickColorTokens, textThreshold: Double) {
        #expect(ratio(tokens.ink, tokens.canvas) >= textThreshold)
        #expect(ratio(tokens.secondary, tokens.canvas) >= textThreshold)
        #expect(ratio(tokens.onEmber, tokens.ember) >= textThreshold)
        #expect(ratio(tokens.ember, tokens.canvas) >= textThreshold)
        #expect(ratio(tokens.outline, tokens.canvas) >= 3)
        #expect(ratio(tokens.error, tokens.errorSurface) >= textThreshold)
        #expect(ratio(tokens.error, tokens.canvas) >= textThreshold)
    }

    private func ratio(_ foreground: UInt32, _ background: UInt32) -> Double {
        let first = luminance(foreground)
        let second = luminance(background)
        return (max(first, second) + 0.05) / (min(first, second) + 0.05)
    }

    private func luminance(_ color: UInt32) -> Double {
        0.2126 * channel((color >> 16) & 255) + 0.7152 * channel((color >> 8) & 255) + 0.0722 * channel(color & 255)
    }

    private func channel(_ value: UInt32) -> Double {
        let normalized = Double(value) / 255
        return normalized <= 0.04045 ? normalized / 12.92 : pow((normalized + 0.055) / 1.055, 2.4)
    }
}
