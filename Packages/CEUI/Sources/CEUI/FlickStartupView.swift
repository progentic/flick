#if os(iOS)
import SwiftUI

public struct FlickStartupView: View {
    public let failed: Bool
    public let retry: () -> Void
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    public init(failed: Bool, retry: @escaping () -> Void) {
        self.failed = failed
        self.retry = retry
    }

    public var body: some View {
        let palette = FlickPalette(dark: scheme == .dark, highContrast: contrast == .increased)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if failed {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(palette.error)
                            .accessibilityHidden(true)
                        Text("Couldn't open notes.")
                            .font(.title2.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        Button(action: retry) {
                            Text("Try again").fontWeight(.semibold)
                                .frame(maxWidth: .infinity, minHeight: 52).padding(.horizontal, 16)
                                .foregroundStyle(palette.onEmber)
                                .background(palette.ember, in: RoundedRectangle(cornerRadius: 12))
                        }.accessibilityIdentifier("retryOpen")
                    } else {
                        ProgressView("Opening Flick…").tint(palette.ember)
                    }
                }.padding(24)
            }.background(palette.canvas).foregroundStyle(palette.ink).navigationTitle("Flick")
        }
    }
}
#endif
