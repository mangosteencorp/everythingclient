#if canImport(SwiftfinLib)
import SwiftfinLib
#endif
import SwiftUI
import UIKit

@available(iOS 16.0, *)
public struct SwiftfinLaunchView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {
        SwiftfinRuntime.configureIfNeeded()
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
            // Swiftfin's SwiftfinAppValueObservation mutates the host app's key
            // window on launch and never reverts it: it forces dark mode
            // (overrideUserInterfaceStyle) and paints the window tint with its
            // accent colour (.jellyfinPurple when signed out), which is what
            // turns our Settings buttons purple once Swiftfin has been opened.
            resetKeyWindowAppearance()
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

    private func resetKeyWindowAppearance() {
        guard let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) else { return }

        keyWindow.overrideUserInterfaceStyle = .unspecified
        // nil falls back to the app's AccentColor asset (unset here, so the
        // system default), matching how the window looked before launching.
        keyWindow.tintColor = nil
    }
}
