import SwiftfinLib
import SwiftUI
import UIKit

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
        .onDisappear {
            // Swiftfin forces the app's key window into dark mode
            // (overrideUserInterfaceStyle) on launch and never reverts it.
            resetInterfaceStyle()
        }
    }

    private func resetInterfaceStyle() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .overrideUserInterfaceStyle = .unspecified
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
