import SwiftfinLib
import SwiftUI

@available(iOS 16.0, *)
struct SwiftfinLaunchView: View {
    @Environment(\.dismiss) private var dismiss

    init() {
        SwiftfinLaunchConfiguration.configureIfNeeded()
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
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
