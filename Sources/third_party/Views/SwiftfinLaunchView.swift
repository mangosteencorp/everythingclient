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
        .onAppear { SwiftfinWindowAppearanceGuard.swiftfinWillAppear() }
        // Swiftfin repaints the host window's tint and forces dark mode; see the guard for why a
        // one-off reset here isn't enough.
        .onDisappear { SwiftfinWindowAppearanceGuard.swiftfinDidDisappear() }
    }

    #if !canImport(SwiftfinLib)
    // SwiftfinLib is only linked on iOS (see Package.swift); keep the screen navigable elsewhere.
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
}
