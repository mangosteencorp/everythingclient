// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
#if canImport(SwiftfinLib)
import SwiftfinLib
#endif
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
            #if canImport(SwiftfinLib)
            SwiftfinView()
            #else
            unavailablePlaceholder
            #endif

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

    #if !canImport(SwiftfinLib)
    // SwiftfinLib is dropped from the package graph on Swift 6.4+ toolchains
    // (see Package.swift); keep the screen navigable until that port lands.
    private var unavailablePlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "play.tv")
                .font(.system(size: 44, weight: .light))
            Text("Swiftfin is unavailable in this build.")
                .font(.headline)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    #endif

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
        #if canImport(SwiftfinLib)
        SwiftfinLibrary.configure()
        #endif
        isConfigured = true
    }
}
#endif
