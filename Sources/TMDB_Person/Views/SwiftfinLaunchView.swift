import SwiftfinLib
import SwiftUI

@available(iOS 16.0, *)
public struct SwiftfinLaunchView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {
        SwiftfinLaunchConfiguration.configureIfNeeded()
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            SwiftfinView()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .padding(16)
            }
            .accessibilityLabel("Close Swiftfin")
            .accessibilityIdentifier("swiftfin.close.button")
        }
    }
}

private enum SwiftfinLaunchConfiguration {
    private static var isConfigured = false

    static func configureIfNeeded() {
        guard !isConfigured else { return }
        SwiftfinLibrary.configure()
        isConfigured = true
    }
}
